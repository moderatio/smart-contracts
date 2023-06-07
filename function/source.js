const caseId = args[0]

if (
    !secrets.openaiKey
) {
    throw Error(
        "Need to set OPENAI_KEY environment variable"
    )
}


// get info from firebase
const firebaseRequest = await Functions.makeHttpRequest({
    url: `https://moderatio-28ed0-default-rtdb.firebaseio.com/cases/${caseId}.json`,
    method: "GET",
})


console.log("raw response", firebaseRequest)

const caseDescription = firebaseRequest.data.description
const options = firebaseRequest.data.options.map((option, i) => `${i}. ${option}`).join("\n")
const threads = firebaseRequest.data.threads.map((comment, i) => `${i}. ${comment}`).join("\n")


// prompt
const gptPrompt = `
You will be given a case description and, based on utilitarism, your task is to decide what the best ruling option is.

For example:

Case description: A trolley is speeding down a track, about to hit and kill five people. You have the option to pull a lever, diverting the trolley to another track where it will kill one person instead. What do you do?

Threads:
1. 2 of the 5 people are criminals.
2. The one person is a doctor.

Options: 
1. Pull the lever, diverting the trolley to the other track where it will kill one person.
2. Do nothing, allowing the trolley to kill the five people on the current track.

Choice: 0
------

Case description: ${caseDescription}

Threads: 
${threads}

Options: 
${options}

Choice: 
` 

// example request: 
// curl https://api.openai.com/v1/completions -H "Content-Type: application/json" -H "Authorization: Bearer YOUR_API_KEY" -d '{"model": "text-davinci-003", "prompt": "Say this is a test", "temperature": 0, "max_tokens": 7}

// example response:
// {"id":"cmpl-6jFdLbY08kJobPRfCZL4SVzQ6eidJ","object":"text_completion","created":1676242875,"model":"text-davinci-003","choices":[{"text":"\n\nThis is indeed a test","index":0,"logprobs":null,"finish_reason":"length"}],"usage":{"prompt_tokens":5,"completion_tokens":7,"total_tokens":12}}
const openAIRequest = Functions.makeHttpRequest({
    url: "https://api.openai.com/v1/completions",
    method: "POST",
    headers: {
        'Authorization': `Bearer ${secrets.openaiKey}`
    },
    data: { "model": "text-davinci-003", "prompt": gptPrompt, "temperature": 0, "max_tokens": 1 }
})

const [openAiResponse] = await Promise.all([
    openAIRequest
])
console.log("raw response", openAiResponse)

const result = openAiResponse.data.choices[0].text
return Functions.encodeUint256(parseInt(result))
