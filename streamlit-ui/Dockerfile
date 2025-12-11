FROM python:3.12-slim

WORKDIR /app

ADD ./streamlit-ui /app
ADD ./objects-python-client /app/objects-python-client
ADD .env .env
ADD ./python-requirements.txt /app/python-requirements.txt

RUN pip install --no-cache-dir -r python-requirements.txt
RUN pip install ./objects-python-client

EXPOSE 8501

CMD ["streamlit", "run", "main.py"]
