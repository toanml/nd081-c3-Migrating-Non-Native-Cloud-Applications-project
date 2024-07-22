import logging
import azure.functions as func
import psycopg2
from datetime import datetime
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from .. import settings

def main(msg: func.ServiceBusMessage):

    notification_id = int(msg.get_body().decode('utf-8'))
    logging.info('Python ServiceBus queue trigger processed message: %s',notification_id)
    #Connect to db 
    # Construct connection string
    conn_string = "host={0} user={1} dbname={2} password={3} sslmode={4}".format(settings.POSTGRES_URL, settings.POSTGRES_USER, settings.POSTGRES_DB, settings.POSTGRES_PW, 'require')

    # Variables
    nbr_attendees = 0
    email_subject = ""
    email_body = ""
    notification_date = datetime.utcnow()

    # Connect to DB
    try:
        conn = psycopg2.connect(conn_string)
        logging.info("Connection established")
        cursor = conn.cursor()
    except (Exception, Error) as error:
        logging.info("Error while connecting to PostgreSQL", error)
        if (conn):
            cursor.close()
            conn.close()


    try:
        # Get notification message and subject from database using the notification_id
        notification_query = '''SELECT subject, message 
                                FROM notification
                                WHERE id = {};'''
        cursor.execute(notification_query.format(notification_id))

        # Get attendee email and name by notification id
        notification = cursor.fetchone()
        subject = notification[0]
        message = notification[1]

        # Loop through each attendee and send an email with a personalized subject
        cursor.execute("SELECT email, first_name FROM attendee;")
        attendees = cursor.fetchall()
        #Start to send email notification
        for attendee in attendees:
            first_name = attendee[0]
            email = attendee[1]
            custom_subject = '{}: {}'.format(first_name, subject)
            send_email(email, custom_subject, message)
            
        status = "Notified {} attendees".format(len(attendees))
        cursor.execute("UPDATE notification SET status = '{}', completed_date = '{}' WHERE id = {};".format(status, datetime.utcnow(), notification_id))
        conn.commit()

    except (Exception, psycopg2.DatabaseError) as error:
        logging.error(error)
        conn.rollback()
    finally:
        if conn:
            cursor.close()
            conn.close()
            

def send_email(email, subject, body):
    #Create message 
    msg = MIMEMultipart()
    msg['From'] = settings.ADMIN_EMAIL_ADDRESS
    msg['Subject'] = subject
    msg['To'] = ', '.join(email)
    body = body
    msg.attach(MIMEText(body,'plain'))
    #Connect SMTP Gmail Server
    try:
        server = smtplib.SMTP('smtp.gmail.com', 587)
        server.starttls()
        server.login(settings.GMAIL_USER, settings.GMAIL_PASSWORD)
        #Send email
        text = msg.as_string()
        server.sendmail(settings.ADMIN_EMAIL_ADDRESS, email, text) 
        server.quit()
        print(f'Email was sent to {", ".join(email)}')
    except Exception as e:
        logging.error(e)
        print(f'Email was failed to send to {", ".join(email)} with error {e}')