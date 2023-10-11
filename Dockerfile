ARG FUNCTION_DIR="/home/function/"
ARG RUNTIME_VERSION="3.11"

# Stage 1 - Create a bundle of the base image and the AWS runtime
FROM python:${RUNTIME_VERSION} AS build-image

ARG FUNCTION_DIR
ARG RUNTIME_VERSION

# Create function directory
RUN mkdir -p ${FUNCTION_DIR}

# Copy function code and model
COPY function/* ${FUNCTION_DIR}

# Install the function's dependencies
RUN python${RUNTIME_VERSION} -m pip install --no-cache-dir -r ${FUNCTION_DIR}/requirements.txt --target ${FUNCTION_DIR}

# Install the Lambda Runtime Interface Client for Python
RUN python${RUNTIME_VERSION} -m pip install --no-cache-dir awslambdaric --target ${FUNCTION_DIR}

# Stage 2 - Create the final runtime image from a fresh copy of the Python slim image
FROM python:${RUNTIME_VERSION}-slim

ARG FUNCTION_DIR

WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}

# Add Lambda Runtime Interface Emulator for local testing
ADD https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie /usr/bin/aws-lambda-rie
COPY entry.sh /
RUN chmod 755 /usr/bin/aws-lambda-rie /entry.sh

# Use the entry script as the container's entry point
ENTRYPOINT [ "/entry.sh" ]
CMD [ "lambda_function.handler" ]