const supabaseUrl = 'https://hbjkykoqyrlrisqendkl.supabase.co';
const apiKey = 'sb_publishable_Exfmd5MHN5TImD7d9kO-xg_JkGY9Rz_';

async function run() {
  const email = `temp_${Date.now()}@test.com`;
  const password = 'tempPassword123!';

  console.log('Registering a temporary authenticated user...');
  let token = '';

  try {
    // 1. Sign Up
    const signupRes = await fetch(`${supabaseUrl}/auth/v1/signup`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': apiKey
      },
      body: JSON.stringify({ email, password, data: { nama: 'Temp User', role: 'pegawai' } })
    });

    const signupData = await signupRes.json();
    if (signupData.access_token) {
      token = signupData.access_token;
      console.log('Successfully registered.');
    } else {
      console.log('Register failed, trying login with existing credentials...');
      // 2. Sign In (Fallback if sign up failed or we have a reuse flow)
      const loginRes = await fetch(`${supabaseUrl}/auth/v1/token?grant_type=password`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'apikey': apiKey
        },
        body: JSON.stringify({ email, password })
      });
      const loginData = await loginRes.json();
      token = loginData.access_token;
    }

    if (!token) {
      console.error('Failed to get access token');
      process.exit(1);
    }

    console.log('Token acquired. Fetching arsip_surat & disposisi...');
    // Query table
    const queryUrl = `${supabaseUrl}/rest/v1/arsip_surat?nomor_surat=eq.12354&select=*,disposisi(*)`;
    const res = await fetch(queryUrl, {
      headers: {
        'apikey': apiKey,
        'Authorization': `Bearer ${token}`
      }
    });

    const data = await res.json();
    console.log('\n--- DATA ---');
    console.log(JSON.stringify(data, null, 2));

  } catch (err) {
    console.error('Error during execution:', err);
  }
}

run();
