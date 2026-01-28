// Supabase Edge Function for Account Deletion
// This should be deployed to: supabase/functions/delete-account/index.ts
// Deploy with: supabase functions deploy delete-account

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get the authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'Missing authorization header' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Create Supabase client with user's auth token
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      { global: { headers: { Authorization: authHeader } } }
    )

    // Verify the user is authenticated
    const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    const userId = user.id

    // Create admin client for deleting the user
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      }
    )

    console.log(`Deleting all data for user: ${userId}`)

    // Delete user data in order (respecting foreign key constraints)
    
    // 1. Delete all workout sets
    const { error: setsError } = await supabaseAdmin
      .from('sets')
      .delete()
      .eq('user_id', userId)
    
    if (setsError) {
      console.error('Error deleting sets:', setsError)
      throw new Error(`Failed to delete sets: ${setsError.message}`)
    }

    // 2. Delete all body weight logs
    const { error: logsError } = await supabaseAdmin
      .from('body_weight_logs')
      .delete()
      .eq('user_id', userId)
    
    if (logsError) {
      console.error('Error deleting body weight logs:', logsError)
      throw new Error(`Failed to delete body weight logs: ${logsError.message}`)
    }

    // 3. Delete user-exercise associations
    const { error: userExercisesError } = await supabaseAdmin
      .from('user_exercises')
      .delete()
      .eq('user_id', userId)
    
    if (userExercisesError) {
      console.error('Error deleting user exercises:', userExercisesError)
      throw new Error(`Failed to delete user exercises: ${userExercisesError.message}`)
    }

    // 4. Delete user profile
    const { error: profileError } = await supabaseAdmin
      .from('user_profiles')
      .delete()
      .eq('user_id', userId)
    
    if (profileError) {
      console.error('Error deleting user profile:', profileError)
      throw new Error(`Failed to delete user profile: ${profileError.message}`)
    }

    // 5. Delete the auth user (THIS IS THE KEY PART!)
    const { error: deleteUserError } = await supabaseAdmin.auth.admin.deleteUser(userId)
    
    if (deleteUserError) {
      console.error('Error deleting user account:', deleteUserError)
      throw new Error(`Failed to delete user account: ${deleteUserError.message}`)
    }

    console.log(`Successfully deleted user account: ${userId}`)

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account and all associated data deleted successfully'
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error in delete-account function:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Failed to delete account',
        message: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
