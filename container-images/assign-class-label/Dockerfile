FROM python:3.12-slim

WORKDIR /app/

COPY requirements.txt ./

RUN pip install -r requirements.txt

COPY . ./

EXPOSE 5000

CMD ["gunicorn", "wsgi:webhook", "--log-level=info", "--workers", "3", "--bind", "0.0.0.0:5000", "--keyfile", "/certs/webhook.key", "--certfile", "/certs/webhook.crt"]
