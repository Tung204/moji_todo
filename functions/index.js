const functions = require("firebase-functions/v2");
const admin = require("firebase-admin");

admin.initializeApp();

// HTTP Function để xử lý sao lưu
exports.backupUsers = functions.https.onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const usersSnapshot = await db.collection("users").get();

    if (usersSnapshot.empty) {
      console.log("No users found for backup.");
      res.status(200).send("No users found for backup.");
      return;
    }

    const batch = db.batch();
    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      console.log(`Backing up data for user: ${userId}`);
      const userRef = db.collection("users").doc(userId);
      batch.set(
          userRef,
          {lastBackup: admin.firestore.FieldValue.serverTimestamp()},
          {merge: true});
    }

    await batch.commit();
    console.log("Backup completed successfully.");
    res.status(200).send("Backup completed successfully.");
  } catch (error) {
    console.error("Error during backup:", error);
    res.status(500).send("Backup failed: " + error.message);
  }
});
