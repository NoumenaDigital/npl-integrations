FROM python:3.12-slim

WORKDIR /app

ADD ./streamlit-ui /app
ADD .env .env

RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8501

CMD ["streamlit", "run", "main.py"]
