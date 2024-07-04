import pandas as pd
import pyodbc

# Configuration de la connexion a la nouvelle instance SQL Server
server = 'SRV-WDS'
database = 'master'
username = 'sa'
password = 'motdepassedb'
connection_string = f'DRIVER={{ODBC Driver 17 for SQL Server}};SERVER={server};DATABASE={database};UID={username};PWD={password}'

# Charger le fichier CSV
df = pd.read_csv("logins.csv")

# Fonction pour créer les commandes SQL
def create_sql_commands(df):
    commands = []
    for index, row in df.iterrows():
        login = row['LoginName']
        password_hash = row['PasswordHash']

        create_login_command = f"""
        USE [master];
        CREATE LOGIN [{login}] WITH PASSWORD = 'password_hash', DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[Français], CHECK_EXPIRATION=OFF, CHECK_POLICY=ON;
        ALTER LOGIN [{login}] DISABLE;
        """

        # Ajoutez chaque commande SQL à la liste
        commands.append(create_login_command)

    return commands

# Générer les commandes SQL
sql_commands = create_sql_commands(df)

# Se connecter à la base de données et exécuter les commandes SQL
with pyodbc.connect(connection_string) as conn:
    cursor = conn.cursor()
    for command in sql_commands:
        cursor.execute(command)
        conn.commit()

print("Logins créés avec succès.")
