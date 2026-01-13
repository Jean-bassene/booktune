#!/usr/bin/env python3
"""
📧 BOOKTUNE PARTNERSHIP CAMPAIGN AUTOMATION

Script pour automatiser la campagne de contact partenaires.
Utilise les templates préparés pour envoyer des emails personnalisés.

Prérequis:
- pip install smtplib email
- Configurer les credentials email dans config.py
"""

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import time
import json
from datetime import datetime

class PartnershipCampaign:
    def __init__(self, smtp_server="smtp.gmail.com", smtp_port=587):
        self.smtp_server = smtp_server
        self.smtp_port = smtp_port
        self.sender_email = None
        self.sender_password = None
        self.contacts_sent = set()

    def setup_credentials(self, email, password):
        """Configure les credentials email"""
        self.sender_email = email
        self.sender_password = password
        print(f"✅ Credentials configurés pour {email}")

    def load_contacts(self, filename="PARTNERS_CONTACTS.json"):
        """Charge la liste des contacts depuis un fichier JSON"""
        try:
            with open(filename, 'r', encoding='utf-8') as f:
                contacts = json.load(f)
            print(f"✅ {len(contacts)} contacts chargés")
            return contacts
        except FileNotFoundError:
            print(f"❌ Fichier {filename} non trouvé")
            return []

    def create_personalized_email(self, contact, your_name, your_company="BookTune"):
        """Crée un email personnalisé pour un contact"""

        subject = f"Proposition de Partenariat Affiliation - {your_company} App"

        body = f"""Cher/Chère {contact.get('name', 'Contact')},

Je m'appelle {your_name}, fondateur de {your_company}, une application mobile innovante de lecture d'audiobooks qui révolutionne l'expérience d'écoute de livres audio.

Notre application, disponible sur Android et iOS, combine :
- Une bibliothèque personnelle avec import de fichiers locaux
- Un catalogue gratuit de +15,000 livres via LibriVox
- Un lecteur audio professionnel avec contrôles avancés
- Des fonctionnalités uniques comme les ambiances sonores intégrées

Nous avons récemment finalisé notre version 1.0 et souhaitons établir des partenariats d'affiliation avec les meilleurs catalogues d'audiobooks payants.

**Proposition concrète :**
- Intégration de votre catalogue dans {your_company} via API
- Commission attractive de {contact.get('commission', '30-40%')} sur les ventes générées
- Trafic qualifié d'utilisateurs passionnés de livres audio
- Promotion croisée de nos deux plateformes

Notre application compte déjà des utilisateurs actifs et présente un taux de rétention solide.

Seriez-vous disponible pour un appel de 15 minutes afin d'explorer les possibilités de collaboration ?

Je reste à votre disposition pour tout renseignement complémentaire.

Cordialement,
{your_name}
Fondateur, {your_company}
{self.sender_email}
[Link to BookTune website/GitHub]
"""

        return subject, body

    def send_email(self, recipient_email, subject, body):
        """Envoie un email via SMTP"""
        try:
            # Créer le message
            msg = MIMEMultipart()
            msg['From'] = self.sender_email
            msg['To'] = recipient_email
            msg['Subject'] = subject

            # Ajouter le corps
            msg.attach(MIMEText(body, 'plain', 'utf-8'))

            # Connexion SMTP
            server = smtplib.SMTP(self.smtp_server, self.smtp_port)
            server.starttls()
            server.login(self.sender_email, self.sender_password)

            # Envoi
            server.send_message(msg)
            server.quit()

            print(f"✅ Email envoyé à {recipient_email}")
            return True

        except Exception as e:
            print(f"❌ Erreur envoi email à {recipient_email}: {e}")
            return False

    def send_campaign_emails(self, contacts, your_name, delay_seconds=30):
        """Envoie la campagne d'emails avec délai entre chaque envoi"""

        if not self.sender_email or not self.sender_password:
            print("❌ Configurez d'abord les credentials avec setup_credentials()")
            return

        print(f"🚀 Début de la campagne: {len(contacts)} emails à envoyer")
        print(f"⏱️  Délai entre emails: {delay_seconds} secondes")

        sent_count = 0
        failed_count = 0

        for i, contact in enumerate(contacts, 1):
            email = contact.get('email')
            name = contact.get('name', 'Contact')

            if not email:
                print(f"⚠️  Email manquant pour {name}")
                continue

            if email in self.contacts_sent:
                print(f"⏭️  Email déjà envoyé à {email}")
                continue

            print(f"\n📧 [{i}/{len(contacts)}] Envoi à {name} <{email}>")

            subject, body = self.create_personalized_email(contact, your_name)
            success = self.send_email(email, subject, body)

            if success:
                sent_count += 1
                self.contacts_sent.add(email)
            else:
                failed_count += 1

            # Délai entre envois (éviter spam)
            if i < len(contacts):
                print(f"⏳ Attente {delay_seconds}s...")
                time.sleep(delay_seconds)

        print("
📊 RÉSULTATS DE LA CAMPAGNE:"        print(f"✅ Emails envoyés: {sent_count}")
        print(f"❌ Échecs: {failed_count}")
        print(f"📈 Taux de succès: {(sent_count/(sent_count+failed_count)*100):.1f}%")


def main():
    """Fonction principale pour exécuter la campagne"""

    # Configuration
    campaign = PartnershipCampaign()

    # ⚠️  À CONFIGURER AVANT UTILISATION
    YOUR_EMAIL = "your.email@example.com"
    YOUR_PASSWORD = "your_app_password"  # Utiliser un app password Gmail
    YOUR_NAME = "Jean Bassene"

    campaign.setup_credentials(YOUR_EMAIL, YOUR_PASSWORD)

    # Charger les contacts
    contacts = campaign.load_contacts()

    if not contacts:
        print("❌ Aucun contact trouvé. Créez d'abord PARTNERS_CONTACTS.json")
        return

    # Demander confirmation
    print(f"\n📧 CAMPAGNE PRÊTE")
    print(f"Destinataires: {len(contacts)}")
    print(f"Expéditeur: {YOUR_EMAIL}")
    print(f"Nom: {YOUR_NAME}")

    confirm = input("\nConfirmer l'envoi de la campagne ? (oui/non): ").lower().strip()

    if confirm in ['oui', 'yes', 'y', 'o']:
        # Lancer la campagne
        campaign.send_campaign_emails(contacts, YOUR_NAME)
    else:
        print("❌ Campagne annulée")


if __name__ == "__main__":
    main()
