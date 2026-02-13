# ------------ Build stage ------------
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy only csproj first for efficient restore
COPY dnmgithbuactionsdemo.csproj ./
RUN dotnet restore dnmgithbuactionsdemo.csproj

# Copy the rest of the source
COPY . .

# Publish as self-contained files into /app
RUN dotnet publish dnmgithbuactionsdemo.csproj -c Release -o /app --no-restore

# ------------ Runtime stage ------------
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS runtime
WORKDIR /app
COPY --from=build /app ./

# Listen on 8080 in the container
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

# If you need non-root user, uncomment these lines:
# RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
# USER appuser

ENTRYPOINT ["dotnet", "dnmgithbuactionsdemo.dll"]
