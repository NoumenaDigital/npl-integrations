# Use an official Python runtime as a parent image
FROM python:3.12-slim

# Set the working directory in the container to /app
WORKDIR /app

# Add the current directory contents into the container at /app
ADD ./python-listener /app
ADD ./iou-python-client /app/iou-python-client
ADD .env .env
ADD ./python-requirements.txt /app/python-requirements.txt

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir -r python-requirements.txt
RUN pip install ./iou-python-client

# Make port 80 available to the world outside this container
EXPOSE 80

# Run app.py when the container launches
CMD ["python", "-u", "app.py"]
