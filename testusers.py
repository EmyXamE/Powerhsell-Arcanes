import pandas as pd

def create_sql_commands(df):
    commands = []
    for index, row in df.iterrows():
        login = row['LoginName']
        password_hash = row['PasswordHash']
        
        commands = f"""
        USE [master];
        CREATE LOGIN [{login}] WITH PASSWORD = {password_hash}, DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[Français], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON;
        ALTER LOGIN [{login}] DISABLE;
        """
        
    print(commands)
















server = 'SRV-WDS\RDM'
database = 'master'
username = 'sa'
password = 'motdepassedb'
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'

df = pd.read_csv("logins.csv")

sql_commands = create_sql_commands(df)