FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /project

# Copy the server-side code into the container
COPY handler.py /project/
COPY requirements.txt /project/
COPY file.txt /project/

# Install the required dependencies
RUN pip install -m requirements.txt

# Run the server-side code when the container starts
CMD [ "python3", "./handler.py" ]