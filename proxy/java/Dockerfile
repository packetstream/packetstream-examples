FROM eclipse-temurin:25-jdk AS build
WORKDIR /src
COPY Main.java .
RUN javac -Xlint:all -Werror -d /out Main.java

FROM eclipse-temurin:25-jre
WORKDIR /app
COPY --from=build /out/ .

# Run as an unprivileged user
USER nobody
CMD ["java", "Main"]
