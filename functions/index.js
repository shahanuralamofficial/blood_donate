const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

/**
 * Triggered when a blood request status changes to 'completed'.
 * Handles the 80/20 split from Escrow to Wallets.
 */
exports.handlePaymentRelease = functions.firestore
    .document('blood_requests/{requestId}')
    .onUpdate(async (change, context) => {
        const newData = change.after.data();
        const oldData = change.before.data();

        if (newData.status === 'completed' && oldData.status !== 'completed' && newData.requestType === 'paid') {
            const amount = newData.agreedPrice;
            const donorId = newData.donorId;
            const platformFee = amount * 0.20;
            const donorShare = amount * 0.80;

            const batch = db.batch();

            const donorWalletRef = db.collection('wallets').doc(donorId);
            batch.set(donorWalletRef, {
                balance: admin.firestore.FieldValue.increment(donorShare),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            const adminWalletRef = db.collection('wallets').doc('platform_admin');
            batch.set(adminWalletRef, {
                balance: admin.firestore.FieldValue.increment(platformFee),
                updatedAt: admin.firestore.FieldValue.serverTimestamp()
            }, { merge: true });

            const txRef = db.collection('transactions').doc();
            batch.set(txRef, {
                requestId: context.params.requestId,
                senderId: newData.requesterId,
                receiverId: donorId,
                amount: amount,
                platformFee: platformFee,
                donorShare: donorShare,
                type: 'payment_release',
                status: 'success',
                timestamp: admin.firestore.FieldValue.serverTimestamp()
            });

            const requestRef = db.collection('blood_requests').doc(context.params.requestId);
            batch.update(requestRef, { paymentStatus: 'released' });

            return batch.commit();
        }
        return null;
    });

/**
 * Triggered when a new blood request is created.
 * Sends notification to donors with matching blood group if it's an emergency.
 */
exports.notifyEmergencyRequest = functions.firestore
    .document('blood_requests/{requestId}')
    .onCreate(async (snapshot, context) => {
        const requestData = snapshot.data();

        if (requestData.isEmergency) {
            const bloodGroup = requestData.bloodGroup;

            // Query users who are donors and have this blood group
            const donorsSnapshot = await db.collection('users')
                .where('role', '==', 'donor')
                .where('bloodGroup', '==', bloodGroup)
                .get();

            const tokens = [];
            donorsSnapshot.forEach(doc => {
                const data = doc.data();
                if (data.fcmToken) {
                    tokens.push(data.fcmToken);
                }
            });

            if (tokens.length > 0) {
                const payload = {
                    notification: {
                        title: `জরুরি ${bloodGroup} রক্ত প্রয়োজন!`,
                        body: `${requestData.hospitalName} হাসপাতালে জরুরি রক্ত প্রয়োজন। দ্রুত অ্যাপে দেখুন।`,
                        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
                    },
                    data: {
                        requestId: context.params.requestId,
                        type: 'emergency_request'
                    }
                };

                return admin.messaging().sendToDevice(tokens, payload);
            }
        }
        return null;
    });
