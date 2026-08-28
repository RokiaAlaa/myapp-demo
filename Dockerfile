FROM python:3.11-slim
WORKDIR /app
RUN pip install flask pytest
COPY app.py test_app.py .
EXPOSE 8000
CMD ["python", "app.py"]