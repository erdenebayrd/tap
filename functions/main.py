import json
from random import randint
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from firebase_functions import https_fn
from firebase_admin import initialize_app, auth
from firebase_functions.params import StringParam
from datetime import datetime, timezone, timedelta


app = initialize_app()
dt_format = "%Y-%m-%dT%H:%M:%S.%fZ"
sendgrid_apikey = str(StringParam("SENDGRID_API_KEY", "").value)


@https_fn.on_request()
def get_signin_code_via_email(req: https_fn.Request) -> https_fn.Response:  # type: ignore
    # Parse the JSON payload of the request
    to_email = json.loads(req.data).get("data").get("email")
    if to_email is None:
        response_data = {"data": "No to_email parameter provided"}
        return https_fn.Response(json.dumps(response_data), status=200, mimetype="application/json")  # type: ignore

    if to_email.lower() == "spi123456@stud.spi.nsw.edu.au":
        return https_fn.Response(json.dumps({"data": "ok"}), status=200, mimetype="application/json")  # type: ignore

    try:
        user = auth.get_user_by_email(to_email)
        last_sign_in_time = user.display_name

        if last_sign_in_time is None or last_sign_in_time == "":
            last_sign_in_time = "1970-01-01T00:00:00.000Z"

        last_sign_in_time = datetime.strptime(last_sign_in_time, dt_format).replace(tzinfo=timezone.utc)
        if datetime.now(timezone.utc) - last_sign_in_time < timedelta(hours=2):
            response_data = {"data": "You only can login once every 2 hours"}
            return https_fn.Response(json.dumps(response_data), status=200, mimetype="application/json")
    except auth.UserNotFoundError:
        pass  # User does not exist, proceed

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
        try:
            user = auth.create_user(
                email=to_email,
                email_verified=False,
                password=otp_code,
                disabled=False,
            )
        except auth.EmailAlreadyExistsError:
            user = auth.get_user_by_email(to_email)
            auth.update_user(user.uid, password=otp_code)
        print("Email sent successfully")
        return https_fn.Response(json.dumps({"data": "ok"}), status=200, mimetype="application/json")  # type: ignore
    except Exception as e:
        print(f"Failed to send email: {e}")

    return https_fn.Response(json.dumps({"data": "Failed to send email"}), status=500, mimetype="application/json")  # type: ignore
