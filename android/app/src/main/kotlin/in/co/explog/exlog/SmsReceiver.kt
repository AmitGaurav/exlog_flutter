package `in`.co.explog.exlog

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore

/**
 * Manifest-registered receiver for the system SMS_RECEIVED broadcast — works
 * even when the Flutter engine/app process isn't running, since this is a
 * protected system broadcast. Deliberately does the minimum here: a
 * lightweight keyword pre-filter (so SMS that isn't even loosely financial
 * never leaves the device), then writes only pre-filtered candidates to
 * Firestore for the Dart-side SmsParsingOrchestrator to fully parse. Requires
 * only RECEIVE_SMS (not READ_SMS) — we never scan inbox history, only SMS
 * delivered going forward.
 */
class SmsReceiver : BroadcastReceiver() {

    companion object {
        // Must match shared_preferences' legacy SharedPreferences-backed file
        // name/key-prefix convention (pubspec: shared_preferences ^2.3.3) so
        // the Settings toggle written from Dart is visible here without a
        // MethodChannel round-trip.
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val ENABLED_KEY = "flutter.sms_auto_detect_enabled"

        private val bankNames = listOf(
            "hdfc", "icici", "sbi", "axis", "kotak", "yes bank", "idbi",
            "bank of baroda", "bob", "punjab national bank", "pnb", "union bank",
            "canara", "indian bank", "central bank", "indusind", "federal bank",
            "hsbc", "citi", "standard chartered", "scbl", "deutsche", "abn amro",
            "rbl bank",
        )
        private val upiProviders = listOf(
            "google pay", "googlepay", "phonepe", "paytm", "bhim", "whatsapp pay",
            "amazon pay", "flipkart", "razorpay", "instamojo", "imobile", "mobikwik",
        )
        private val transactionKeywords = listOf(
            "debited", "credited", "transaction", "paid", "received", "transfer",
            "withdrawn", "deposited", "balance", "upi", "atm", "emi",
        )

        private fun looksFinancial(body: String): Boolean {
            val lower = body.lowercase()
            if (bankNames.any { lower.contains(it) }) return true
            if (upiProviders.any { lower.contains(it) }) return true
            val hasKeyword = transactionKeywords.any { lower.contains(it) }
            val hasCurrency = lower.contains("rs") || lower.contains("inr") || lower.contains("₹") ||
                Regex("\\d+(?:,\\d{3})*").containsMatchIn(lower)
            return hasKeyword && hasCurrency
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Telephony.Sms.Intents.SMS_RECEIVED_ACTION) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        if (!prefs.getBoolean(ENABLED_KEY, false)) return

        val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
        if (messages.isNullOrEmpty()) return

        val sender = messages[0].originatingAddress ?: return
        val body = messages.joinToString(separator = "") { it.messageBody ?: "" }
        if (body.isBlank() || !looksFinancial(body)) return

        val uid = FirebaseAuth.getInstance().currentUser?.uid ?: return

        val doc = hashMapOf(
            "sender" to sender,
            "body" to body,
            "receivedAt" to FieldValue.serverTimestamp(),
            "status" to "unprocessed",
        )
        FirebaseFirestore.getInstance()
            .collection("users").document(uid)
            .collection("androidSmsInbox")
            .add(doc)
    }
}
