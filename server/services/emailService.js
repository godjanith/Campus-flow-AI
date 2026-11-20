import nodemailer from 'nodemailer';

export const sendNotificationEmail = async (toEmail, subject, textContent) => {
  try {
    if (!process.env.EMAIL_USER || process.env.EMAIL_USER.includes('your_email')) {
      console.log(`[Mock Email] To: ${toEmail} | Subject: ${subject} | Body: ${textContent}`);
      return true;
    }
    const transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: process.env.EMAIL_USER,
        pass: process.env.EMAIL_PASS
      }
    });

    await transporter.sendMail({
      from: '"CampusFlow AI" <no-reply@campusflow.ai>',
      to: toEmail,
      subject: subject,
      text: textContent
    });
    console.log(`Email sent successfully to ${toEmail}`);
  } catch (error) {
    console.error(`Email send failed: ${error.message}`);
  }
};
