FROM python:3.13-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN addgroup -S relay && adduser -S -G relay relay
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY --chown=relay:relay server.py privacy.html ./
USER relay
EXPOSE 8765
CMD ["python", "server.py"]
