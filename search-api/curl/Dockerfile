FROM alpine:3.24

RUN apk add --no-cache bash curl jq

WORKDIR /app
COPY run.sh .

USER nobody
ENTRYPOINT ["./run.sh"]
