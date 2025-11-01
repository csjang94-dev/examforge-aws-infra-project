import chainlit as cl
import openai

openai.api_base = "http://localhost:1234/v1"
openai.api_key = "lm-studio"

@cl.on_message
async def main(message):
    response = openai.ChatCompletion.create(
        model="사용할 모델 이름",
        messages=[{"role": "user", "content": message.content}]
    )
    await cl.Message(content=response.choices[0].message.content).send()
