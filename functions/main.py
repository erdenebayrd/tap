import json
from random import randint
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail
from firebase_functions import https_fn
from firebase_admin import initialize_app, auth
from firebase_functions.params import StringParam


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
                display_name=to_email,
                disabled=False,
            )
        except auth.EmailAlreadyExistsError:
            user = auth.get_user_by_email(to_email)
            auth.update_user(user.uid, password=otp_code)
        print("Email sent successfully")
        return https_fn.Response(json.dumps({"data": user.uid}), status=200, mimetype="application/json")  # type: ignore
    except Exception as e:
        print(f"Failed to send email: {e}")

    return https_fn.Response(json.dumps({"data": "Failed to send email"}), status=500, mimetype="application/json")  # type: ignore
