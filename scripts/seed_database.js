const admin = require('firebase-admin');
const serviceAccount = require('../serviceAccountKey.json');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// Helper for timestamps
const timestamp = admin.firestore.FieldValue.serverTimestamp();
const getTimeStamp = (daysAgo) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return admin.firestore.Timestamp.fromDate(date);
};

// Seed emergency contacts
async function seedEmergencyContacts() {
  console.log('Seeding emergency contacts...');
  
  const contacts = [
    {
      name: 'Police Department',
      number: '911',
      category: 'Emergency',
      description: 'For emergencies requiring police assistance',
      createdAt: timestamp,
      updatedAt: timestamp
    },
    {
      name: 'Fire Department',
      number: '911',
      category: 'Emergency',
      description: 'For fire emergencies',
      createdAt: timestamp,
      updatedAt: timestamp
    },
    {
      name: 'Ambulance Services',
      number: '911',
      category: 'Medical',
      description: 'For medical emergencies',
      createdAt: timestamp,
      updatedAt: timestamp
    },
    {
      name: 'Poison Control Center',
      number: '1-800-222-1222',
      category: 'Medical',
      description: 'For poison-related emergencies',
      createdAt: timestamp,
      updatedAt: timestamp
    },
    {
      name: 'City Hall',
      number: '555-123-4567',
      category: 'Government',
      description: 'For general city inquiries',
      createdAt: timestamp,
      updatedAt: timestamp
    }
  ];

  for (const contact of contacts) {
    await db.collection('emergency_contacts').add(contact);
  }
  
  console.log('Emergency contacts seeded successfully!');
}

// Seed some announcements
async function seedAnnouncements() {
  console.log('Seeding announcements...');
  
  const announcements = [
    {
      title: 'COVID-19 Vaccine Clinic',
      content: 'A COVID-19 vaccine clinic will be held at the Community Center on Saturday from 9 AM to 5 PM. No appointment necessary. Please bring ID and insurance card if available.',
      category: 'Health',
      authorId: 'admin',
      authorName: 'Public Health Department',
      views: 245,
      createdAt: getTimeStamp(5),
      updatedAt: getTimeStamp(5)
    },
    {
      title: 'Road Construction Notice',
      content: 'Main Street will be closed between Oak Avenue and Pine Street from Monday through Friday next week for road repairs. Please use alternate routes during this time.',
      category: 'Infrastructure',
      authorId: 'admin',
      authorName: 'Department of Transportation',
      views: 189,
      createdAt: getTimeStamp(3),
      updatedAt: getTimeStamp(3)
    },
    {
      title: 'Summer Recreation Programs',
      content: 'Registration for summer recreation programs is now open. Programs include swimming lessons, sports camps, and arts classes for all ages. Register online or at the Community Center.',
      category: 'Education',
      authorId: 'admin',
      authorName: 'Parks and Recreation Department',
      views: 156,
      createdAt: getTimeStamp(2),
      updatedAt: getTimeStamp(2)
    },
    {
      title: 'Neighborhood Watch Meeting',
      content: 'A neighborhood watch meeting will be held at the Community Center on Thursday at 7 PM. Local police officers will be present to discuss recent community safety concerns.',
      category: 'Safety',
      authorId: 'admin',
      authorName: 'Police Department',
      views: 112,
      createdAt: getTimeStamp(1),
      updatedAt: getTimeStamp(1)
    }
  ];

  for (const announcement of announcements) {
    const docRef = await db.collection('announcements').add(announcement);
    
    // Add some comments to the first announcement
    if (announcement.title === 'COVID-19 Vaccine Clinic') {
      await docRef.collection('comments').add({
        text: 'Will proof of residency be required?',
        isAnonymous: false,
        userId: 'citizen1',
        userName: 'John Smith',
        createdAt: getTimeStamp(4)
      });
      
      await docRef.collection('comments').add({
        text: 'Is there parking available at the Community Center?',
        isAnonymous: false,
        userId: 'citizen2',
        userName: 'Mary Johnson',
        createdAt: getTimeStamp(3)
      });
      
      await docRef.collection('comments').add({
        text: 'Thank you for organizing this clinic!',
        isAnonymous: true,
        userId: null,
        userName: 'Anonymous',
        createdAt: getTimeStamp(2)
      });
    }
  }
  
  console.log('Announcements seeded successfully!');
}

// Seed polls
async function seedPolls() {
  console.log('Seeding polls...');
  
  const polls = [
    {
      title: 'New Park Development',
      description: 'Which amenities would you like to see in the new city park?',
      options: {
        'Playground': 15,
        'Basketball Court': 8,
        'Walking Trails': 22,
        'Dog Park': 12
      },
      createdBy: 'admin',
      creatorName: 'Parks Department',
      isAnonymous: true,
      createdAt: getTimeStamp(7),
      expiryDate: getTimeStamp(-30), // 30 days from now
      totalVotes: 57,
      isActive: true
    },
    {
      title: 'City Festival Theme',
      description: 'What theme would you prefer for this year\'s city festival?',
      options: {
        'Cultural Heritage': 18,
        'Science & Technology': 12,
        'Environmental Awareness': 9,
        'Arts & Music': 25
      },
      createdBy: 'admin',
      creatorName: 'Events Committee',
      isAnonymous: false,
      createdAt: getTimeStamp(4),
      expiryDate: getTimeStamp(-15), // 15 days from now
      totalVotes: 64,
      isActive: true
    }
  ];

  for (const poll of polls) {
    await db.collection('polls').add(poll);
  }
  
  console.log('Polls seeded successfully!');
}

// Main function
async function seedDatabase() {
  try {
    await seedEmergencyContacts();
    await seedAnnouncements();
    await seedPolls();
    
    console.log('Database seeded successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Error seeding database:', error);
    process.exit(1);
  }
}

// Run the seed function
seedDatabase(); 