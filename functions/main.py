import json
from random import randint
import google.cloud.firestore
from datetime import datetime
from firebase_functions import https_fn
from firebase_admin import initialize_app, firestore


app = initialize_app()


@https_fn.on_request()
def alive(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    print("Req -> ", req)
    response_data = {"data": {"message": "I'm alive!"}}

    return https_fn.Response(json.dumps(response_data), mimetype="application/json")  # type: ignore


@https_fn.on_request()
def get_signin_code_via_email(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    email = req.args.get("email")
    if email is None:
        return https_fn.Response("No email parameter provided", status=400)  # type: ignore

    otp_code = "".join(["{}".format(randint(0, 9)) for _ in range(0, 6)])
    firestore_client: google.cloud.firestore.Client = firestore.client()

    _, doc_ref = (
        firestore_client.collection("users")
        .document(email)
        .collection("logins")
        .add({"otp_code": otp_code, "created_at": datetime.now()})
    )

    print("--------------")
    print(_)
    print("_--------------_")
    print(doc_ref)
    print("--------------")
    return doc_ref


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
