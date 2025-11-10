import { onRequest } from "firebase-functions/v2/https";
import { onDocumentDeleted } from "firebase-functions/v2/firestore"; // Updated for removed functions
import { onSchedule } from "firebase-functions/v2/scheduler"; // Added for scheduled functions
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";

admin.initializeApp();

const SPOONACULAR_KEY = defineSecret("SPOONACULAR_KEY");

const db = admin.firestore();
const messaging = admin.messaging();

interface NotificationSettings {
    expiredItems: boolean;
    atRiskItems: boolean;
    daysForAtRisk: number;
    inactivityReminder: boolean; // New setting for inactivity reminders
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

interface NotificationSummary {
    userId: string;
    householdId: string;
    items: {
        itemId: string;
        productName: string;
        daysUntilExpiry: number;
        type: "expired" | "at_risk";
        status: "pending_action" | "sent";
        createdAt: admin.firestore.Timestamp;
    }[];
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
async function runPantryCheckLogic(targetUserId?: string) {
    console.log(`Executing pantry check logic for user: ${targetUserId || "all users"}`);
    let usersSnapshot;
    if (targetUserId) {
        const userDoc = await db.collection("users").doc(targetUserId).get();
        if (!userDoc.exists) {
            console.log(`Target user ${targetUserId} not found. Skipping pantry check.`);
            return;
        }
        usersSnapshot = { docs: [userDoc] };
    } else {
        usersSnapshot = await db.collection("users").get();
    }

    for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userSettings = userDoc.data()?.notificationSettings;
        const settings: NotificationSettings = {
            expiredItems: userSettings?.expiredItems ?? true,
            atRiskItems: userSettings?.atRiskItems ?? true,
            daysForAtRisk: userSettings?.daysForAtRisk ?? 7,
            inactivityReminder: userSettings?.inactivityReminder ?? true, // Added for interface consistency
        };
        console.log(`Using notification settings for user ${userId}:`, settings);

        if (!settings.expiredItems && !settings.atRiskItems) {
            console.log(`Notifications are disabled for user ${userId}. Skipping pantry check for this user.`);
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

                // Skip item if expirationDate is missing or null
                if (!expirationDate) {
                    console.warn(`Pantry item ${item.name} (${item.id}) in household ${householdId} is missing an expirationDate. Skipping.`);
                    continue;
                }

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
                    const summaryDocId = `${userId}_${householdId}`;
                    const summaryRef = db.collection("notificationSummaries").doc(summaryDocId);

                    const existingSummary = (await summaryRef.get()).data() as NotificationSummary | undefined;

                    const newItem = {
                        itemId: item.id,
                        productName: item.name,
                        daysUntilExpiry: daysUntilExpiry,
                        type: promptType as "expired" | "at_risk",
                        status: "pending_action" as "pending_action" | "sent",
                        createdAt: now,
                    };

                    const updatedItems = existingSummary?.items ? [...existingSummary.items] : [];

                    // Check if an item with the same itemId already exists in the summary
                    const existingItemIndex = updatedItems.findIndex(
                        (summaryItem) => summaryItem.itemId === newItem.itemId,
                    );

                    if (existingItemIndex > -1) {
                        // Update existing item, ensuring status is pending_action if it's still relevant
                        updatedItems[existingItemIndex] = { ...newItem, status: "pending_action" }; // Explicitly set to pending_action
                        console.log(`Updated item ${item.name} in notification summary for user ${userId}, household ${householdId}`);
                    } else {
                        // Add new item
                        updatedItems.push(newItem);
                        console.log(`Added item ${item.name} to notification summary for user ${userId}, household ${householdId}`);
                    }

                    await summaryRef.set({
                        userId: userId,
                        householdId: householdId,
                        items: updatedItems,
                    });
                }
            }
        }
    }
    console.log("Pantry check logic finished.");
}

// Extracted logic for processing and sending notifications
async function processAndSendNotifications(targetUserId?: string) {
    console.log(`Executing notification sending logic for user: ${targetUserId || "all users"}`);
    let summariesQuery: admin.firestore.Query<NotificationSummary> = db.collection("notificationSummaries") as admin.firestore.CollectionReference<NotificationSummary>;

    if (targetUserId) {
        summariesQuery = summariesQuery.where("userId", "==", targetUserId) as admin.firestore.Query<NotificationSummary>;
    }

    const summariesSnapshot = await summariesQuery.get();

    if (summariesSnapshot.empty) {
        console.log("No pending notification summaries to send.");
        return;
    }

    for (const summaryDoc of summariesSnapshot.docs) {
        const summary = summaryDoc.data();
        const userId = summary.userId;
        const householdId = summary.householdId;

        const pendingItems = summary.items.filter(item => item.status === "pending_action");

        if (pendingItems.length === 0) {
            console.log(`No pending items in summary for user ${userId} in household ${householdId}. Skipping.`);
            continue;
        }

        const userProfileDoc = await db.collection("users").doc(userId).get();
        const userProfile = userProfileDoc.data() as UserProfile | undefined;

        if (!userProfile?.fcmToken) {
            console.log(`User ${userId} has no FCM token. Skipping notification for household ${householdId}.`);
            continue;
        }

        const householdDoc = await db.collection("households").doc(householdId).get();
        const household = householdDoc.data() as Household | undefined;
        const householdName = household?.name || "Your Pantry";

        const expiredItems: string[] = [];
        const atRiskItems: string[] = [];

        for (const item of pendingItems) {
            if (item.type === "expired") {
                expiredItems.push(item.productName);
            } else if (item.type === "at_risk") {
                const daysText = item.daysUntilExpiry === 1 ? "1 day" : `${item.daysUntilExpiry} days`;
                atRiskItems.push(`${item.productName} (${daysText} left)`);
            }
        }

        let notificationBody = "";
        if (expiredItems.length > 0) {
            notificationBody += `Expired ${expiredItems.length} items: ${expiredItems.join(", ")}. `;
        }
        if (atRiskItems.length > 0) {
            notificationBody += `At risk ${atRiskItems.length} items: ${atRiskItems.join(", ")}.`;
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

            // Re-enable in-app notification creation
            await addAppNotificationToFirestore(
                userId,
                householdId,
                `[${householdName}] Pantry Alert!`, // Use a concise, consistent title
                notificationBody.trim(), // The body contains the full details
                "pantry_summary",
                message.data,
            );

            // Update the status of sent items in the summary document
            const updatedItems = summary.items.map(item =>
                pendingItems.some(pending => pending.itemId === item.itemId)
                    ? { ...item, status: "sent" }
                    : item
            );

            await summaryDoc.ref.update({ items: updatedItems });
            console.log(`Updated notification summary for user ${userId}, household ${householdId}`);

        } catch (error) {
            console.error(`Failed to send summary notification to user ${userId} for household ${householdId}:`, error);
            // Optional: Handle token cleanup if it's invalid
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

    // Find all notification summaries and iterate to find the item
    const allSummariesSnapshot = await db.collection("notificationSummaries").get();

    if (allSummariesSnapshot.empty) {
        console.log(`No notification summaries found. Skipping cleanup for deleted item ${deletedItem.name}.`);
        return;
    }

    const batch = db.batch();
    let updatesCount = 0;

    for (const doc of allSummariesSnapshot.docs) {
        const summary = doc.data() as NotificationSummary;
        const initialItemCount = summary.items.length;
        const updatedItems = summary.items.filter(item => item.itemId !== deletedItem.id);

        if (updatedItems.length < initialItemCount) {
            // Only update if the item was actually removed
            if (updatedItems.length === 0) {
                // If no items left, delete the summary document
                batch.delete(doc.ref);
                console.log(`Deleted empty notification summary for user ${summary.userId}, household ${summary.householdId}`);
            } else {
                // Otherwise, update the items array
                batch.update(doc.ref, { items: updatedItems });
                console.log(`Removed item ${deletedItem.name} from notification summary for user ${summary.userId}, household ${summary.householdId}`);
            }
            updatesCount++;
        }
    }

    if (updatesCount > 0) {
        try {
            await batch.commit();
            console.log(`Cleaned up notification summaries for deleted item ${deletedItem.name}. Total summaries updated/deleted: ${updatesCount}.`);
        } catch (error) {
            console.error(`Failed to clean up summaries for item ${deletedItem.name}:`, error);
        }
    } else {
        console.log(`No notification summaries needed cleanup for deleted item ${deletedItem.name}.`);
    }
});

// 1. dailyPantryCheck Cloud Function
// Runs every day at 3:00 AM in the specified timezone.
export const dailyPantryCheck = onSchedule({
    schedule: "every day 03:00",
    timeZone: "Asia/Manila",
}, async () => { // Removed unused context parameter
    console.log("Executing dailyPantryCheck trigger");
    await runPantryCheckLogic();
});


// 2. sendReminderNotifications Cloud Function
// Runs every day at 9:00 AM in the specified timezone.
export const sendReminderNotifications = onSchedule({
    schedule: "every day 09:00",
    timeZone: "Asia/Manila",
}, async () => { // Removed unused context parameter
    console.log("Executing sendReminderNotifications");
    await processAndSendNotifications();
    console.log("sendReminderNotifications finished.");
});

// Temporary HTTP-triggered function for testing notifications
export const testSendReminderNotifications = onRequest(async (req, res) => {
    const targetUserId = req.query.userId as string | undefined;
    console.log(`Executing testSendReminderNotifications via HTTP request for user: ${targetUserId || "all users"}`);
    try {
        await processAndSendNotifications(targetUserId);
        res.status(200).send(`Test notifications sent successfully for user: ${targetUserId || "all users"}!`);
    } catch (error) {
        console.error("Error in testSendReminderNotifications:", error);
        res.status(500).send(`Error sending test notifications: ${error}`);
    }
});

// Temporary HTTP-triggered function to manually run dailyPantryCheck
export const testDailyPantryCheck = onRequest(async (req, res) => {
    const targetUserId = req.query.userId as string | undefined;
    console.log(`Executing testDailyPantryCheck via HTTP request for user: ${targetUserId || "all users"}`);
    try {
        await runPantryCheckLogic(targetUserId);
        res.status(200).send(`Test dailyPantryCheck executed successfully for user: ${targetUserId || "all users"}!`);
    } catch (error) {
        console.error("Error in testDailyPantryCheck:", error);
        res.status(500).send(`Error executing testDailyPantryCheck: ${error}`);
    }
});

// Extracted logic for sending inactivity reminders
async function runInactivityReminderLogic(targetUserId?: string) {
    console.log(`Executing inactivity reminder logic for user: ${targetUserId || "all users"}`);
    const now = admin.firestore.Timestamp.now();
    const sevenDaysAgo = new admin.firestore.Timestamp(now.seconds - (7 * 24 * 60 * 60), now.nanoseconds);

    let usersQuery: admin.firestore.Query = db.collection("users");
    if (targetUserId) {
        usersQuery = usersQuery.where(admin.firestore.FieldPath.documentId(), "==", targetUserId);
    } else {
        usersQuery = usersQuery.where("lastActivity", "<", sevenDaysAgo);
    }

    const usersSnapshot = await usersQuery.get();

    if (usersSnapshot.empty) {
        console.log("No users found for inactivity reminder.");
        return;
    }

    for (const userDoc of usersSnapshot.docs) {
        const userId = userDoc.id;
        const userProfile = userDoc.data() as UserProfile | undefined;
        const userSettings = userDoc.data()?.notificationSettings;
        const settings: NotificationSettings = {
            expiredItems: userSettings?.expiredItems ?? true,
            atRiskItems: userSettings?.atRiskItems ?? true,
            daysForAtRisk: userSettings?.daysForAtRisk ?? 7,
            inactivityReminder: userSettings?.inactivityReminder ?? true, // Default to true
        };

        if (!userProfile?.fcmToken) {
            console.log(`User ${userId} has no FCM token. Skipping inactivity reminder.`);
            continue;
        }

        if (!settings.inactivityReminder) {
            console.log(`Inactivity reminders disabled for user ${userId}. Skipping.`);
            continue;
        }

        const message: admin.messaging.Message = {
            token: userProfile.fcmToken,
            notification: {
                title: "ShelfControl: Don't forget your pantry!",
                body: "It's been a while! Check your pantry, update items, and plan your next meal.",
            },
            data: {
                action: "open_app", // Or a specific screen if desired
            },
            android: {
                notification: {
                    clickAction: "FLUTTER_NOTIFICATION_CLICK",
                },
            },
            apns: {
                payload: {
                    aps: {
                        category: "INACTIVITY_REMINDER_CATEGORY",
                    },
                },
            },
        };

        try {
            await messaging.send(message);
            console.log(`Sent inactivity reminder to user ${userId}`);
        } catch (error) {
            console.error(`Failed to send inactivity reminder to user ${userId}:`, error);
        }
    }
    console.log("Inactivity reminder check finished.");
}

// 3. sendInactivityReminder Cloud Function
// Runs weekly (e.g., every Sunday at 10:00 AM) to remind inactive users.
export const sendInactivityReminder = onSchedule({
    schedule: "every sunday 10:00",
    timeZone: "Asia/Manila",
}, async () => {
    console.log("Executing sendInactivityReminder trigger");
    await runInactivityReminderLogic();
});

// Temporary HTTP-triggered function for testing inactivity reminders
export const testSendInactivityReminder = onRequest(async (req, res) => {
    const targetUserId = req.query.userId as string | undefined;
    console.log(`Executing testSendInactivityReminder via HTTP request for user: ${targetUserId || "all users"}`);
    try {
        await runInactivityReminderLogic(targetUserId);
        res.status(200).send(`Test inactivity reminders sent successfully for user: ${targetUserId || "all users"}!`);
    } catch (error) {
        console.error("Error in testSendInactivityReminder:", error);
        res.status(500).send(`Error sending test inactivity reminders: ${error}`);
    }
});

// Find recipes by ingredients (pantry → candidates)
export const spoonacularFindByIngredients = onRequest(
  { region: "asia-southeast1", secrets: [SPOONACULAR_KEY] },
  async (req, res) => {
    try {
      const { ingredients, number = 24, ranking = 1 } = req.body || {};
      if (!Array.isArray(ingredients) || ingredients.length === 0) {
        res.status(400).json({ error: "ingredients[] required" });
        return;
      }

      // Node 18+ has built-in fetch; no node-fetch needed
      const apiKey = SPOONACULAR_KEY.value();
      const url = new URL("https://api.spoonacular.com/recipes/findByIngredients");
      url.searchParams.set("apiKey", apiKey);
      url.searchParams.set("ingredients", ingredients.join(","));
      url.searchParams.set("number", String(number));
      url.searchParams.set("ranking", String(ranking)); // 1 = maximize used ingredients

      const r = await fetch(url.toString());
      const data = await r.json();
      res.json(data);
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message || "spoonacular proxy error" });
    }
  }
);

// Hydrate a recipe with details/nutrition
export const spoonacularGetRecipeInfo = onRequest(
  { region: "asia-southeast1", secrets: [SPOONACULAR_KEY] },
  async (req, res) => {
    try {
      const { id } = req.body || {};
      if (!id) {
        res.status(400).json({ error: "id required" });
        return;
      }

      const apiKey = SPOONACULAR_KEY.value();
      const url = new URL(`https://api.spoonacular.com/recipes/${id}/information`);
      url.searchParams.set("apiKey", apiKey);
      url.searchParams.set("includeNutrition", "true");

      const r = await fetch(url.toString());
      const data = await r.json();
      res.json(data);
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message || "spoonacular info error" });
    }
  }
);

const GEMINI_KEY = defineSecret("AIzaSyAzAQ0YFpbli-T2PUK1daqTAFRcrQGJG7A");

export const aiEnhanceRecipes = onRequest(
  { region: "asia-southeast1", secrets: [GEMINI_KEY] },
  async (req, res) => {
    try {
      const { recipes, locale = "en-PH" } = req.body || {};
      if (!Array.isArray(recipes) || recipes.length === 0) {
        res.status(400).json({ error: "recipes[] required" });
        return;
      }
      // Call Gemini (use fetch with JSON payload). Pseudocode:
      const apiKey = GEMINI_KEY.value();
      const r = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="+apiKey, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text:
`You are enhancing structured recipes.
- Keep ingredients unchanged
- Fix steps to clear, numbered imperative sentences
- Use metric (g, ml); keep servings
- If calories missing, estimate and mark as estimated:true
- Locale: ${locale}
JSON in, JSON out: array of {id, steps[], timeMin?, kcalPerServing?, notes?}
INPUT: ${JSON.stringify(recipes)}`
            }]
          }]
        })
      });
      const data = await r.json();
      // parse model output; assume JSON in first candidate
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "[]";
      const enhanced = JSON.parse(text);
      res.json(enhanced);
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message || "aiEnhanceRecipes error" });
    }
  }
);

export const aiSuggestFromPantry = onRequest(
  { region: "asia-southeast1", secrets: [GEMINI_KEY] },
  async (req, res) => {
    try {
      const { pantry, prefs, nearExpiryDays = 5 } = req.body || {};
      if (!Array.isArray(pantry)) {
        res.status(400).json({ error: "pantry[] required" });
        return;
      }
      const apiKey = GEMINI_KEY.value();
      const r = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key="+apiKey, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          contents: [{
            parts: [{
              text:
`You generate pantry-only recipes. Rules:
- Use ONLY ingredients listed in "pantryNames" (except staples: water, oil, salt, pepper).
- Prefer items expiring in <= ${nearExpiryDays} days.
- Output JSON array: [{id,title,ingredients:[{name,qty,unit}],steps[],servings?,timeMin?,kcalPerServing?}]

pantryNames: ${JSON.stringify(pantry)}
prefs: ${JSON.stringify(prefs || {})}`
            }]
          }]
        })
      });
      const data = await r.json();
      const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "[]";
      const arr = JSON.parse(text);
      res.json(arr);
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message || "aiSuggestFromPantry error" });
    }
  }
);
// (SPOONACULAR_KEY already defined)

export const spoonacularSearchImage = onRequest(
  { region: "asia-southeast1", secrets: [SPOONACULAR_KEY] },
  async (req, res) => {
    try {
      const { query } = req.body || {};
      if (!query || !query.trim()) {
        res.status(400).json({ error: "query required" });
        return;
      }
      const apiKey = SPOONACULAR_KEY.value();
      const url = new URL("https://api.spoonacular.com/recipes/complexSearch");
      url.searchParams.set("apiKey", apiKey);
      url.searchParams.set("query", query);
      url.searchParams.set("number", "1");
      url.searchParams.set("addRecipeInformation", "false");
      url.searchParams.set("instructionsRequired", "false");

      const r = await fetch(url.toString());
      const data = await r.json();
      res.json(data);
    } catch (e: any) {
      console.error(e);
      res.status(500).json({ error: e.message || "spoonacularSearchImage error" });
    }
  }
);
