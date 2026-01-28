//
//  index.ts
//  Plates
//
//  Created by Yuval Arie on 1/27/26.
//

// Supabase Edge Function for Bug Report Submission
// Deploy this to your Supabase project

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BugReport {
  platform: string
  subject: string
  description: string
}

interface GitHubIssueRequest {
  title: string
  body: string
  labels: string[]
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const GITHUB_TOKEN = Deno.env.get('GITHUB_TOKEN')
    const GITHUB_REPO_OWNER = Deno.env.get('GITHUB_REPO_OWNER')
    const GITHUB_REPO_NAME = Deno.env.get('GITHUB_REPO_NAME')

    if (!GITHUB_TOKEN || !GITHUB_REPO_OWNER || !GITHUB_REPO_NAME) {
      throw new Error('Missing required environment variables')
    }

    // Verify authentication (optional but recommended)
    const authHeader = req.headers.get('Authorization')
    if (authHeader) {
      const supabaseClient = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_ANON_KEY') ?? '',
        { global: { headers: { Authorization: authHeader } } }
      )

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
    }

    // Parse request body
    const bugReport: BugReport = await req.json()
    const { platform, subject, description } = bugReport

    // Validate input
    if (!platform || !subject || !description) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: platform, subject, description' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Prepare GitHub issue
    const issueTitle = `[${platform}] ${subject}`
    const issueBody = `**Platform:** ${platform}

## Description
${description}

---
*Reported via Plates iOS app*`

    const githubIssue: GitHubIssueRequest = {
      title: issueTitle,
      body: issueBody,
      labels: ['bug', platform.toLowerCase()]
    }

    // Create GitHub issue
    const githubResponse = await fetch(
      `https://api.github.com/repos/${GITHUB_REPO_OWNER}/${GITHUB_REPO_NAME}/issues`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${GITHUB_TOKEN}`,
          'Accept': 'application/vnd.github+json',
          'Content-Type': 'application/json',
          'X-GitHub-Api-Version': '2022-11-28',
        },
        body: JSON.stringify(githubIssue)
      }
    )

    if (!githubResponse.ok) {
      const errorText = await githubResponse.text()
      console.error('GitHub API error:', errorText)
      throw new Error(`GitHub API returned ${githubResponse.status}`)
    }

    const githubIssue = await githubResponse.json()

    // Return success response
    return new Response(
      JSON.stringify({
        success: true,
        issueUrl: githubIssue.html_url,
        issueNumber: githubIssue.number
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Error creating bug report:', error)
    
    return new Response(
      JSON.stringify({
        error: 'Failed to create bug report',
        message: error.message
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})
