import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import { onDocumentDeleted } from "firebase-functions/v2/firestore"; // Updated for removed functions
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

interface NotificationSettings {
    expiredItems: boolean;
    atRiskItems: boolean;
    daysForAtRisk: number;
    // Add other settings if they are relevant for filtering notifications
}

interface PantryItem {
    id: string;
    name: string;
    expirationDate: admin.firestore.Timestamp;
    householdId: string;
    type?: string;
    daysUntilExpiry?: number;
}

interface UserProfile {
    fcmToken?: string;
}

interface Household {
    id: string;
    name: string;
}

// Helper function to add or update an in-app notification
async function addAppNotificationToFirestore(
    userId: string,
    householdId: string,
    title: string,
    body: string,
    type: string,
    payload: { [key: string]: any } = {},
) {
    try {
        // For pantry_summary, we want to find and update the existing one to avoid duplicates.
        if (type === "pantry_summary") {
            const querySnapshot = await db.collection("appNotifications")
                .where("userId", "==", userId)
                .where("householdId", "==", householdId)
                .where("type", "==", "pantry_summary")
                .limit(1)
                .get();

            if (!querySnapshot.empty) {
                // If an existing summary notification is found, update it.
                const docId = querySnapshot.docs[0].id;
                await db.collection("appNotifications").doc(docId).update({
                    title: title,
                    body: body,
                    payload: JSON.stringify(payload),
                    createdAt: admin.firestore.Timestamp.now(), // Update timestamp to show it's recent
                    isRead: false, // Mark as unread so the user sees the update
                });
                console.log(`Updated pantry_summary notification for user ${userId} in household ${householdId}`);
                return; // Exit after updating
            }
        }

        // If it's not a pantry_summary or no existing one was found, create a new notification.
        await db.collection("appNotifications").add({
            userId: userId,
            householdId: householdId,
            title: title,
            body: body,
            type: type,
            payload: JSON.stringify(payload),
            createdAt: admin.firestore.Timestamp.now(),
            isRead: false,
        });
        console.log(`Added in-app notification for user ${userId} in household ${householdId}`);
    } catch (error) {
        console.error(`Failed to add/update in-app notification for user ${userId}:`, error);
    }
}

// Extracted logic for the daily pantry check
async function runPantryCheckLogic() {
    console.log("Executing pantry check logic");
    const usersSnapshot = await db.collection("users").get();

    for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const settingsDoc = await db.collection("users").doc(userId).collection("notification_settings").doc("settings").get();

        const settings: NotificationSettings = {
            expiredItems: true,
            atRiskItems: true,
            daysForAtRisk: 3,
            ...settingsDoc.data(),
        };

        if (!settings.expiredItems && !settings.atRiskItems) {
            console.log(`User ${userId} has disabled all pantry notifications. Skipping.`);
            continue;
        }

        const userHouseholdsSnapshot = await db.collection("households").where("members", "array-contains", userId).get();

        for (const householdDoc of userHouseholdsSnapshot.docs) {
            const householdId = householdDoc.id;
            const pantryItemsSnapshot = await db.collection("pantryItems").where("householdId", "==", householdId).get();

            for (const itemDoc of pantryItemsSnapshot.docs) {
                const item = { id: itemDoc.id, ...itemDoc.data() } as PantryItem;
                const now = admin.firestore.Timestamp.now();
                const expirationDate = item.expirationDate;
                const daysUntilExpiry = Math.ceil((expirationDate.toMillis() - now.toMillis()) / (1000 * 60 * 60 * 24));

                let shouldCreatePrompt = false;
                let promptType = "";

                if (settings.expiredItems && daysUntilExpiry < 0) {
                    shouldCreatePrompt = true;
                    promptType = "expired";
                } else if (settings.atRiskItems && daysUntilExpiry >= 0 && daysUntilExpiry <= settings.daysForAtRisk) {
                    shouldCreatePrompt = true;
                    promptType = "at_risk";
                }

                if (shouldCreatePrompt) {
                    const promptId = `${userId}_${item.id}`;
                    const promptRef = db.collection("notificationPrompts").doc(promptId);

                    await promptRef.set({
                        userId: userId,
                        householdId: householdId,
                        itemId: item.id,
                        productName: item.name,
                        daysUntilExpiry: daysUntilExpiry,
                        type: promptType,
                        status: "pending_action",
                        createdAt: now,
                    });
                    console.log(`Created prompt for user ${userId}, item ${item.name} in household ${householdId}`);
                }
            }
        }
    }
    console.log("Pantry check logic finished.");
}

// Extracted logic for processing and sending notifications
async function processAndSendNotifications() {
    const promptsSnapshot = await db.collection("notificationPrompts").where("status", "==", "pending_action").get();

    if (promptsSnapshot.empty) {
        console.log("No pending prompts to send.");
        return;
    }

    // Group prompts by userId and householdId
    const userHouseholdPrompts: { [userId: string]: { [householdId: string]: PantryItem[] } } = {};

    for (const promptDoc of promptsSnapshot.docs) {
        const prompt = promptDoc.data();
        const userId = prompt.userId;
        const householdId = prompt.householdId;
        const productName = prompt.productName;
        const daysUntilExpiry = prompt.daysUntilExpiry;
        const type = prompt.type;

        if (!userHouseholdPrompts[userId]) {
            userHouseholdPrompts[userId] = {};
        }
        if (!userHouseholdPrompts[userId][householdId]) {
            userHouseholdPrompts[userId][householdId] = [];
        }
        userHouseholdPrompts[userId][householdId].push({
            id: prompt.itemId,
            name: productName,
            expirationDate: prompt.expirationDate,
            householdId: householdId,
            type: type,
            daysUntilExpiry: daysUntilExpiry,
        } as PantryItem);
    }

    for (const userId in userHouseholdPrompts) {
        const userProfileDoc = await db.collection("users").doc(userId).get();
        const userProfile = userProfileDoc.data() as UserProfile | undefined;

        if (!userProfile?.fcmToken) {
            console.log(`User ${userId} has no FCM token. Skipping.`);
            continue;
        }

        for (const householdId in userHouseholdPrompts[userId]) {
            const householdPrompts = userHouseholdPrompts[userId][householdId];
            const householdDoc = await db.collection("households").doc(householdId).get();
            const household = householdDoc.data() as Household | undefined;
            const householdName = household?.name || "Your Pantry";

            let expiredItems: string[] = [];
            let atRiskItems: string[] = [];

            for (const item of householdPrompts) {
                if (item.type === "expired") {
                    expiredItems.push(item.name);
                } else if (item.type === "at_risk") {
                    const daysText = item.daysUntilExpiry === 1 ? "1 day" : `${item.daysUntilExpiry} days`;
                    atRiskItems.push(`${item.name} (${daysText} left)`);
                }
            }

            let notificationBody = "";
            if (expiredItems.length > 0) {
                notificationBody += `${expiredItems.length} item(s) expired: ${expiredItems.join(", ")}. `;
            }
            if (atRiskItems.length > 0) {
                notificationBody += `${atRiskItems.length} item(s) at risk: ${atRiskItems.join(", ")}.`;
            }

            if (notificationBody === "") {
                console.log(`No relevant items for notification for user ${userId} in household ${householdId}. Skipping.`);
                continue;
            }

            const message: admin.messaging.Message = {
                token: userProfile.fcmToken,
                notification: {
                    title: `[${householdName}] Pantry Alert!`,
                    body: notificationBody.trim(),
                },
                data: {
                    householdId: householdId,
                    action: "view_pantry_alerts",
                },
                android: {
                    notification: {
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                    },
                },
                apns: {
                    payload: {
                        aps: {
                            category: "PANTRY_ALERT_CATEGORY",
                        },
                    },
                },
            };

            try {
                await messaging.send(message);
                console.log(`Sent summary notification to user ${userId} for household ${householdId}`);
                // Add to in-app notification history
                await addAppNotificationToFirestore(
                    userId,
                    householdId,
                    `[${householdName}] Pantry Alert!`, // Use a concise, consistent title
                    notificationBody.trim(), // The body contains the full details
                    "pantry_summary",
                    message.data,
                );

                // Mark all prompts for this user and household as sent
                const batch = db.batch();
                for (const promptDoc of promptsSnapshot.docs) {
                    const prompt = promptDoc.data();
                    if (prompt.userId === userId && prompt.householdId === householdId && prompt.status === "pending_action") {
                        batch.update(promptDoc.ref, { status: "sent" });
                    }
                }
                await batch.commit();
            } catch (error) {
                console.error(`Failed to send summary notification to user ${userId} for household ${householdId}:`, error);
                // Optional: Handle token cleanup if it's invalid
            }
        }
    }
}


// 5. onPantryItemDelete Cloud Function
// Triggers when a pantry item is deleted to clean up associated notification prompts.
export const onPantryItemDelete = onDocumentDeleted("pantryItems/{itemId}", async (event) => {
    const deletedSnapshot = event.data;
    if (!deletedSnapshot) {
        console.log("No data associated with the delete event");
        return;
    }
    const deletedItem = { id: deletedSnapshot.id, ...deletedSnapshot.data() } as PantryItem;
    console.log(`Pantry item deleted: ${deletedItem.name} (${deletedItem.id})`);

    // Find and delete all prompts associated with this item across all users
    const promptsToDeleteSnapshot = await db.collection("notificationPrompts")
        .where("itemId", "==", deletedItem.id)
        .get();

    if (promptsToDeleteSnapshot.empty) {
        console.log(`No notification prompts found for deleted item ${deletedItem.name}.`);
        return;
    }

    const batch = db.batch();
    promptsToDeleteSnapshot.docs.forEach(doc => {
        batch.delete(doc.ref);
    });

    try {
        await batch.commit();
        console.log(`Deleted ${promptsToDeleteSnapshot.docs.length} notification prompts for item ${deletedItem.name}.`);
    } catch (error) {
        console.error(`Failed to delete prompts for item ${deletedItem.name}:`, error);
    }
});

// 1. dailyPantryCheck Cloud Function
// Runs every day at 3:00 AM in the specified timezone.
export const dailyPantryCheck = onSchedule({
    schedule: "every day 03:00",
    timeZone: "Asia/Manila",
}, async (context) => {
    console.log("Executing dailyPantryCheck trigger");
    await runPantryCheckLogic();
});


// 2. sendReminderNotifications Cloud Function
// Runs every day at 9:00 AM in the specified timezone.
export const sendReminderNotifications = onSchedule({
    schedule: "every day 09:00",
    timeZone: "Asia/Manila",
}, async (context) => {
    console.log("Executing sendReminderNotifications");
    await processAndSendNotifications();
    console.log("sendReminderNotifications finished.");
});

// Temporary HTTP-triggered function for testing notifications
export const testSendReminderNotifications = onRequest(async (req, res) => {
    console.log("Executing testSendReminderNotifications via HTTP request");
    try {
        await processAndSendNotifications();
        res.status(200).send("Test notifications sent successfully!");
    } catch (error) {
        console.error("Error in testSendReminderNotifications:", error);
        res.status(500).send(`Error sending test notifications: ${error}`);
    }
});

// Temporary HTTP-triggered function to manually run dailyPantryCheck
export const testDailyPantryCheck = onRequest(async (req, res) => {
    console.log("Executing testDailyPantryCheck via HTTP request");
    try {
        await runPantryCheckLogic();
        res.status(200).send("Test dailyPantryCheck executed successfully!");
    } catch (error) {
        console.error("Error in testDailyPantryCheck:", error);
        res.status(500).send(`Error executing testDailyPantryCheck: ${error}`);
    }
});
