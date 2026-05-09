FROM mcr.microsoft.com/dotnet/sdk:8.0 
WORKDIR /app 
RUN dotnet new tool-manifest && \ 

    dotnet tool install microsoft.dataapibuilder 

COPY dab-config.json . 
EXPOSE 5000 

ENV ASPNETCORE_URLS=http://+:5000 

CMD ["dotnet", "tool", "run", "dab", "start", "--config", "dab-config.json"] 