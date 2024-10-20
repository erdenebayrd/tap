import json
from random import randint
import google.cloud.firestore
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from firebase_functions import https_fn
from datetime import datetime, timedelta
from firebase_functions.params import StringParam
from firebase_admin import initialize_app, firestore


app = initialize_app()
dt_format = "%Y-%m-%d %H:%M:%S"
sendgrid_apikey = str(StringParam("SENDGRID_API_KEY", "").value)


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
        .order_by("created_at", direction=firestore.Query.DESCENDING)  # type: ignore
        .stream()
    )

    for item in logins:
        item = item.to_dict()
        print(item)
        if datetime.now() - datetime.strptime(item.get("created_at"), dt_format) < timedelta(minutes=30):
            return https_fn.Response(json.dumps({"data": item}), status=200, mimetype="application/json")  # type: ignore

    otp_code = "".join(["{}".format(randint(0, 9)) for _ in range(0, 6)])

    try:
        # Connect to Gmail's SMTP server
        sg = SendGridAPIClient(sendgrid_apikey)
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
                    "created_at": datetime.now().strftime(dt_format),
                    "updated_at": datetime.now().strftime(dt_format),
                }
            )
        )
        print("Email sent successfully")
        return https_fn.Response(json.dumps({"data": added_doc_ref.get().to_dict()}), status=200, mimetype="application/json")  # type: ignore
    except Exception as e:
        print(f"Failed to send email: {e}")

    return https_fn.Response(json.dumps({"data": "Failed to send email"}), status=500, mimetype="application/json")  # type: ignore


@https_fn.on_request()
def verify_otp(req: https_fn.Request) -> https_fn.Response:
    data = json.loads(req.data).get("data")
    print("-" * 100)
    print(data)
    print("-" * 100)
    email = data.get("email")
    otp = data.get("otp")

    if not email or not otp:
        response_data = {"data": "Email and OTP are required"}
        return https_fn.Response(json.dumps(response_data), status=200, mimetype="application/json")

    firestore_client: google.cloud.firestore.Client = firestore.client()
    user_ref = firestore_client.collection("users").document(email)

    # Query the latest login attempt
    latest_login = (
        user_ref.collection("logins").order_by("created_at", direction=firestore.Query.DESCENDING).limit(1).get()
    )

    if not latest_login:
        return https_fn.Response(
            json.dumps({"data": "No recent login attempt found"}), status=200, mimetype="application/json"
        )

    latest_login = latest_login[0]
    latest_login_doc_id = latest_login.id
    latest_login = latest_login.to_dict()

    print("-" * 100)
    print(latest_login)
    print("-" * 100)

    if latest_login["otp_code"] == otp:
        # OTP is correct, update the login status
        session_id = int(datetime.now().timestamp() * 1000)  # Current epoch time in milliseconds
        user_ref.collection("logins").document(latest_login_doc_id).set(
            {"is_logged_in": True, "updated_at": datetime.now().strftime(dt_format), "session_id": session_id},
            merge=True,
        )
        return https_fn.Response(
            json.dumps({"data": {**latest_login, "session_id": session_id}}), status=200, mimetype="application/json"
        )
    else:
        return https_fn.Response(json.dumps({"data": "Invalid OTP"}), status=200, mimetype="application/json")
