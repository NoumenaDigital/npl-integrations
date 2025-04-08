FROM python:3.12-slim

WORKDIR /app

ADD ./streamlit-ui /app
ADD ./iou-python-client /app/iou-python-client
ADD .env .env
ADD ./python-requirements.txt /app/python-requirements.txt

RUN pip install --no-cache-dir -r python-requirements.txt
RUN pip install ./iou-python-client

EXPOSE 8501

CMD ["streamlit", "run", "main.py"]
