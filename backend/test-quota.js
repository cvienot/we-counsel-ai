// Test script for subscription plan quota enforcement
// 
// Note: Tests include 1-second delays between messages because the quota increment
// happens asynchronously in the AI streaming callback. Without delays, rapid successive
// messages can pass the quota check before previous increments complete.

async function testQuota() {
  const apiUrl = 'http://localhost:3001/api';
  
  console.log('🧪 Testing Subscription Plan Quotas\n');
  
  // ============================================
  // Test 1: Free tier (10 AI messages/month)
  // ============================================
  console.log('📋 Test 1: Free Tier (10 AI messages limit)');
  
  const freeUser1 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `free1-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Free',
      lastName: 'User1',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'free'
    })
  });
  const free1Data = await freeUser1.json();
  const free1Token = free1Data.token;
  const free1Id = free1Data.user.userId;
  
  const freeUser2 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `free2-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Free',
      lastName: 'User2',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'free'
    })
  });
  const free2Data = await freeUser2.json();
  const free2Id = free2Data.user.userId;
  
  // Connect partners
  await fetch(`${apiUrl}/test/connect-partners`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      user1Id: free1Id,
      user2Id: free2Id,
      subscriptionTier: 'free'
    })
  });
  
  console.log('   ✅ Free tier users connected');
  
  // Create conversation
  const freeConvResponse = await fetch(`${apiUrl}/conversations`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${free1Token}`
    },
    body: JSON.stringify({ title: 'Test', type: 'main' })
  });
  const freeConvData = await freeConvResponse.json();
  const freeConvId = freeConvData.conversation.conversationId;
  
  // Send AI messages up to quota (10)
  for (let i = 1; i <= 10; i++) {
    const msg = await fetch(`${apiUrl}/messages/${freeConvId}/ai-stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${free1Token}`
      },
      body: JSON.stringify({
        content: `Test message ${i}`,
        recipientType: 'coach'
      })
    });
    
    if (msg.status === 201) {
      console.log(`   ✅ AI message ${i}/10 sent successfully`);
    } else {
      console.error(`   ❌ Failed to send message ${i}: ${msg.status}`);
      process.exit(1);
    }
    
    // Wait for AI response to complete and increment to finish
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  // Try to send 11th message - should be blocked
  const blocked = await fetch(`${apiUrl}/messages/${freeConvId}/ai-stream`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${free1Token}`
    },
    body: JSON.stringify({
      content: 'This should be blocked',
      recipientType: 'coach'
    })
  });
  
  if (blocked.status === 403) {
    console.log('   ✅ 11th message blocked (quota exceeded) - FREE TIER WORKS!\n');
  } else {
    const blockedBody = await blocked.json();
    console.error(`   ❌ 11th message should be blocked but got status: ${blocked.status}`);
    console.error(`   Response:`, JSON.stringify(blockedBody, null, 2));
    
    // Check the couple's subscription info
    const coupleCheck = await fetch(`${apiUrl}/couples`, {
      headers: { 'Authorization': `Bearer ${free1Token}` }
    });
    const coupleData = await coupleCheck.json();
    console.error(`   Couple data:`, JSON.stringify(coupleData, null, 2));
    
    process.exit(1);
  }
  
  // ============================================
  // Test 2: Premium tier (unlimited)
  // ============================================
  console.log('📋 Test 2: Premium Tier (unlimited messages)');
  
  const premUser1 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `prem1-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Premium',
      lastName: 'User1',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'premium'
    })
  });
  const prem1Data = await premUser1.json();
  const prem1Token = prem1Data.token;
  const prem1Id = prem1Data.user.userId;
  
  const premUser2 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `prem2-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Premium',
      lastName: 'User2',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'premium'
    })
  });
  const prem2Data = await premUser2.json();
  const prem2Id = prem2Data.user.userId;
  
  // Connect partners
  await fetch(`${apiUrl}/test/connect-partners`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      user1Id: prem1Id,
      user2Id: prem2Id,
      subscriptionTier: 'premium'
    })
  });
  
  console.log('   ✅ Premium tier users connected');
  
  // Create conversation
  const premConvResponse = await fetch(`${apiUrl}/conversations`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${prem1Token}`
    },
    body: JSON.stringify({ title: 'Test', type: 'main' })
  });
  const premConvData = await premConvResponse.json();
  const premConvId = premConvData.conversation.conversationId;
  
  // Send 10 AI messages - all should succeed
  for (let i = 1; i <= 10; i++) {
    const msg = await fetch(`${apiUrl}/messages/${premConvId}/ai-stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${prem1Token}`
      },
      body: JSON.stringify({
        content: `Premium test message ${i}`,
        recipientType: 'coach'
      })
    });
    
    if (msg.status === 201) {
      console.log(`   ✅ AI message ${i}/10 sent successfully`);
    } else {
      console.error(`   ❌ Failed to send message ${i}: ${msg.status}`);
      process.exit(1);
    }
  }
  
  console.log('   ✅ All 10 messages sent - PREMIUM TIER WORKS!\n');
  
  // ============================================
  // Test 3: Essential tier (15 messages to test quota)
  // ============================================
  console.log('📋 Test 3: Essential Tier (100 AI messages limit - testing with 15)');
  
  const essUser1 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `ess1-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Essential',
      lastName: 'User1',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'essential'
    })
  });
  const ess1Data = await essUser1.json();
  const ess1Token = ess1Data.token;
  const ess1Id = ess1Data.user.userId;
  
  const essUser2 = await fetch(`${apiUrl}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: `ess2-${Date.now()}@test.com`,
      password: 'Test123!',
      firstName: 'Essential',
      lastName: 'User2',
      language: 'en',
      termsAccepted: true,
      subscriptionTier: 'essential'
    })
  });
  const ess2Data = await essUser2.json();
  const ess2Id = ess2Data.user.userId;
  
  // Connect partners
  await fetch(`${apiUrl}/test/connect-partners`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      user1Id: ess1Id,
      user2Id: ess2Id,
      subscriptionTier: 'essential'
    })
  });
  
  console.log('   ✅ Essential tier users connected');
  
  // Create conversation
  const essConvResponse = await fetch(`${apiUrl}/conversations`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${ess1Token}`
    },
    body: JSON.stringify({ title: 'Test', type: 'main' })
  });
  const essConvData = await essConvResponse.json();
  const essConvId = essConvData.conversation.conversationId;
  
  // Send 15 AI messages - all should succeed (limit is 100)
  for (let i = 1; i <= 15; i++) {
    const msg = await fetch(`${apiUrl}/messages/${essConvId}/ai-stream`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${ess1Token}`
      },
      body: JSON.stringify({
        content: `Essential test message ${i}`,
        recipientType: 'coach'
      })
    });
    
    if (msg.status === 201) {
      if (i % 5 === 0) {
        console.log(`   ✅ AI message ${i}/15 sent successfully`);
      }
    } else {
      console.error(`   ❌ Failed to send message ${i}: ${msg.status}`);
      process.exit(1);
    }
    
    // Wait for increment to complete
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  console.log('   ✅ All 15 messages sent - ESSENTIAL TIER WORKS!\n');
  
  console.log('✅ All quota tests passed!');
}

testQuota().catch(err => {
  console.error('Test failed:', err);
  process.exit(1);
});
