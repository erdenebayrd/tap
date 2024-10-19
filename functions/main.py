import json
import smtplib
from random import randint
import google.cloud.firestore
from datetime import datetime
from email.mime.text import MIMEText
from firebase_functions import https_fn
from email.mime.multipart import MIMEMultipart
from firebase_functions.params import StringParam
from firebase_admin import initialize_app, firestore


app = initialize_app()


@https_fn.on_request()
def alive(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    print("Req -> ", req)
    response_data = {"data": {"message": "I'm alive!"}}

    return https_fn.Response(json.dumps(response_data), mimetype="application/json")  # type: ignore


# # Usage
# subject = "Test Email"
# body = "This is a test email sent from Python."
# to_email = "recipient@example.com"

# send_email(subject, body, to_email)


@https_fn.on_request()
def get_signin_code_via_email(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    # Parse the JSON payload of the request
    to_email = json.loads(req.data).get("data").get("email")
    if to_email is None:
        response_data = {"error": "No to_email parameter provided"}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype="application/json")  # type: ignore

    otp_code = "".join(["{}".format(randint(0, 9)) for _ in range(0, 6)])

    sender_gmail_address = str(StringParam("EMAIL_ADDRESS"))
    sender_gmail_password = str(StringParam("EMAIL_PASSWORD"))

    # Create the email
    msg = MIMEMultipart()
    msg["From"] = sender_gmail_address
    msg["To"] = to_email
    msg["Subject"] = "OTP CODE"
    msg.attach(MIMEText(f"{otp_code} is your OTP code to login", "plain"))

    try:
        # Connect to Gmail's SMTP server
        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()  # Upgrade the connection to a secure encrypted SSL/TLS connection
        server.login(sender_gmail_address, sender_gmail_password)
        server.sendmail(sender_gmail_address, to_email, msg.as_string())
        server.quit()
        firestore_client: google.cloud.firestore.Client = firestore.client()

        added_doc_time, added_doc_ref = (
            firestore_client.collection("users")
            .document(to_email)
            .collection("logins")
            .add({"otp_code": otp_code, "is_logged_in": False, "created_at": datetime.now()})
        )

        print("Email sent successfully")
        return https_fn.Response(json.dumps({"data": "Email sent successfully!"}), status=200, mimetype="application/json")  # type: ignore
    except Exception as e:
        print(f"Failed to send email: {e}")

    return https_fn.Response(json.dumps({"data": "Failed to send email"}), status=500, mimetype="application/json")  # type: ignore


# @https_fn.on_request()
# def addmessage(req: https_fn.Request) -> https_fn.Response:  # type: ignore
#     """Take the text parameter passed to this HTTP endpoint and insert it into
#     a new document in the messages collection."""
#     # Grab the text parameter.
#     original = req.args.get("text")
#     if original is None:
#         return https_fn.Response("No text parameter provided", status=400)  # type: ignore

#     firestore_client: google.cloud.firestore.Client = firestore.client()

#     # Push the new message into Cloud Firestore using the Firebase Admin SDK.
#     _, doc_ref = firestore_client.collection("messages").add({"original": original})

#     # Send back a message that we've successfully written the message
#     return https_fn.Response(f"Message with ID {doc_ref.id} added.")  # type: ignore
