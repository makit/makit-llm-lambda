# LLM Inside an AWS Lambda Function
Instead of using services such as ChatGPT, Amazon Bedrock, Google Bard - there are several open-source Large language models that can be used to run a chatbot locally, [GPT4ALL](https://gpt4all.io/index.html) is one such option.

This led me to wonder if it was possible to run a LLM inside [AWS Lambda](https://aws.amazon.com/lambda/) function. These are usually small, fast to run, event-driven functions. They are not meant to be used for complex processing tasks, but they do scale-to-zero and you only pay for what you use. Having a LLM inside a Lambda function seems a fun experiment, and a way to have a hosted model that doesn't require a long-running process.\

## Overview
This repository contains code to create a custom runtime AWS Lambda function using a container image. It can be ran locally inside Docker for testing as well. The function contains the full LLM model and the code to use the model, allowing basic text generation from a HTTP call into it.

This uses:
* [LangChain](https://www.langchain.com/)
* [GPT4ALL](https://gpt4all.io/index.html)
* [Python Container Image](https://hub.docker.com/_/python)

## Deploying

1. Download a [GPT4ALL model](https://gpt4all.io/index.html). For this I used [ggml-model-gpt4all-falcon-q4_0.bin](https://huggingface.co/nomic-ai/gpt4all-falcon-ggml/resolve/main/ggml-model-gpt4all-falcon-q4_0.bin) because it is a small model (4GB...) which has good responses. Other models should work, but they need to be small enough to fit in the Lambda memory limits.

2. Place the `bin` file inside the `function` folder, next to the lambda_function.py file.

3. Build the image with docker: `docker build --platform linux/amd64 -t makgpt:test1`.

4. Once built then you can run it locally: `docker run -p 9000:8080 makgpt:test1`

5. Once running then you can run invocations against it in another terminal window, such as `curl "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{"body":"{\"action\":\"Set fire to a tree\"}"}'`

6. Push the image to ECR inside your AWS account. For this you can follow the AWS guide under `Deploying the image` in the [Developer Guide](https://docs.aws.amazon.com/lambda/latest/dg/python-image.html#python-image-clients). The simple steps are:
    * `aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 111122223333.dkr.ecr.us-east-1.amazonaws.com`
    * `aws ecr create-repository --repository-name hello-world --image-scanning-configuration scanOnPush=true --image-tag-mutability MUTABLE`
    * `docker tag docker-image:test <ECRrepositoryUri>:latest`
    * `docker tag docker-image:test 111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest`
    * `docker push 111122223333.dkr.ecr.us-east-1.amazonaws.com/hello-world:latest`

7. Create a Lambda function from this image, ensuring to give it enough memory (10GB recommended) and a timeout of at least 5 minutes.

8. For simplicity, give the Lambda function a [Function URL](https://docs.aws.amazon.com/lambda/latest/dg/lambda-urls.html) and you can hit it over HTTP then.

9. You can then try it with the URL such as: `curl "https://INSERTHERE.lambda-url.us-east-1.on.aws/" -d '{"body":"{\"action\":\"Set fire to a tree\"}"}'`

## Examples
This function is primed as a basic text adventure game with the prompt:

`You are a Text-Based Fantasy RPG. The player is exploring the dark forest and you are the dungeon master. The player performs the action: {action} What happens next? You are talking to the player.`

### Angry Orc

#### Request Body:
```
{
  "action": "Throw your sword at the angry orc"
}
```

#### Response:
```
"\nAs the player throws their sword at the angry orc, it strikes true and lands squarely in its chest. The orc roars in pain and anger, charging towards the player with a fierce look in its eyes.\n\nThe player quickly dodges out of the way, but not before noticing something strange about the orc's eyes. They seem to be glowing with an otherworldly light, as if they are possessed by some dark force.\n\nWith the orc now dangerously close, the player decides to take a risk and try to reason with it. \"Stop! I mean you no harm,\" they say, holding out their hands in a gesture of peace.\n\nTo their surprise, the orc seems to understand them and hesitates for a moment before continuing its attack. The player quickly grabs their sword and prepares to defend themselves if necessary.\n\nAs the fight continues, it becomes clear that this orc is not like any other they have faced before. Its movements are unnaturally quick and its strength is unmatched. But with each blow of the sword, the player gains a little more confidence in their abilities.\n\nFinally, after what seems like an eternity, the orc falls to the ground, defeated."
```
Time taken: `1m 33s`

### Wizard Spell

#### Request Body
```
{
  "action": "A wizard casts a spell on the player and turns them into a pencil"
}
```

#### Response:
```
"\nAs the wizard finishes casting his spell, the player suddenly finds themselves transformed into a pencil. They look down at their new form in confusion before noticing that they are no longer holding the wand they were using to cast spells.\n\nThe player tries to move around, but find that they are unable to do so without making a noise. They try to speak, but find that they cannot make any sounds with their new pencil body.\n\nSuddenly, they hear a voice from behind them. \"Well, well, well. Look who we have here.\" The player turns around to see the wizard who cast the spell on them.\n\nThe wizard chuckles at the player's transformation and begins to speak in a mocking tone. \"I bet you didn't expect this when you decided to mess with magic, did you?\"\n\nThe player tries to respond, but finds that they are unable to do so without making any noise. They feel helpless and frustrated as they try to come up with a plan to escape their new form.\n\nWhat will the player do next?"
```
Time taken: `1m 1s`