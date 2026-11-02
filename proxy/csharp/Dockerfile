FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src
COPY ProxyExample.csproj .
RUN dotnet restore
COPY Program.cs .
RUN dotnet publish --no-restore -c Release -o /out

FROM mcr.microsoft.com/dotnet/runtime:10.0
WORKDIR /app
COPY --from=build /out/ .

# Run as the image's unprivileged user
USER $APP_UID
ENTRYPOINT ["dotnet", "ProxyExample.dll"]
