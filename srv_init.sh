import g4f
import os
import shutil
from yaspin import yaspin

def main(model_name, bot_names, bot_to_bot_mode):
    print("Press Ctrl+C to exit at any time.")
    print(f"Current model: {model_name}\n")
    print(vanity_line())
    try:
        engine = g4f.client.Client()
        with open(f'models\{model_name}.txt', 'r', encoding="utf-8") as file:
            context = file.read()

        chat_history = []
        chat_history.append(("system", context))

        bot_index = 0

        while True:
            if bot_to_bot_mode:
                user_input = ""
            else:
                user_input = input("You: ")
                print()
            if not bot_to_bot_mode:
                chat_history.append(("user", user_input))

            with yaspin().bouncingBar as sp:
                sp.text = "Thinking..."
                completion = engine.chat.completions.create(
                    model="gpt-3.5-turbo", #gpt-4
                    messages=[{"role": "user", "content": content} for _, content in chat_history])
                sp.text = " "

            bot_response = completion.choices[0].message.content
            bot_name = bot_names[bot_index]
            
            if not bot_to_bot_mode:
                bot_name = bot_name.replace("[1] ", "").replace("[2] ", "")
                
            chat_history.append((f"{bot_name}", bot_response))
            print(f"{bot_name}:", bot_response)
            print()

            if bot_to_bot_mode:
                bot_index = (bot_index + 1) % len(bot_names)

    except KeyboardInterrupt:
        print()
        print(vanity_line())
        print("\n\nExiting gracefully...")
        with open("chat_history.txt", "w") as chat_file:
            for role, message in chat_history:
                if role != "system":
                    chat_file.write(f"{role}: {message}\n\n")
        print("Chat history saved to chat_history.txt")
        exit()

    except Exception as e:
        with open("error.log", "a") as error_log:
            error_log.write(str(e) + "\n")
        print("An error occurred:", e)

def vanity_line():
    terminal_width = shutil.get_terminal_size().columns
    dash = "—"
    dashes = dash * (terminal_width - 2)
    return f"<{dashes}>"

if __name__ == "__main__":
    model_name = "pajama_sam"
    bot_names = [f"[1] {model_name.capitalize()}", f"[2] {model_name.capitalize()}"]
    bot_to_bot_mode = False

    with open("error.log", "w") as error_log:
        error_log.write("")

    os.system("cls||clear")
    main(model_name, bot_names, bot_to_bot_mode)
