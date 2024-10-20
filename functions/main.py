import json
from random import randint
import google.cloud.firestore
from datetime import datetime
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from firebase_functions import https_fn
from firebase_functions.params import StringParam
from firebase_admin import initialize_app, firestore


app = initialize_app()


@https_fn.on_request()
def alive(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    print("Req -> ", req)
    response_data = {"data": {"message": "I'm alive!"}}

    return https_fn.Response(json.dumps(response_data), mimetype="application/json")  # type: ignore


@https_fn.on_request()
def get_signin_code_via_email(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    # Parse the JSON payload of the request
    to_email = json.loads(req.data).get("data").get("email")
    if to_email is None:
        response_data = {"error": "No to_email parameter provided"}
        return https_fn.Response(json.dumps(response_data), status=400, mimetype="application/json")  # type: ignore

    firestore_client: google.cloud.firestore.Client = firestore.client()
    logins = (
        firestore_client.collection("users")
        .document(to_email)
        .collection("logins")
        .where("is_logged_in", "==", False)
        .get()
    )
    print("+" * 100)
    print(logins)
    print("+" * 100)
    # TODO: add check whether try to call this function within 5 mins

    otp_code = "".join(["{}".format(randint(0, 9)) for _ in range(0, 6)])

    try:
        # Connect to Gmail's SMTP server
        sg = SendGridAPIClient(str(StringParam("SENDGRID_API_KEY", "").value))
        response = sg.send(
            Mail(
                # from_email="ericd@engineer.com",
                from_email="spi230957@stud.spi.nsw.edu.au",
                to_emails=to_email,
                subject="Hi, OTP code",
                html_content=f"<strong>use this {otp_code} to login</strong>",
            )
        )
        added_doc_time, added_doc_ref = (
            firestore_client.collection("users")
            .document(to_email)
            .collection("logins")
            .add(
                {
                    "otp_code": otp_code,
                    "is_logged_in": False,
                    "created_at": datetime.now(),
                    "updated_at": datetime.now(),
                }
            )
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
