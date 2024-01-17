import streamlit as st
import wikipedia
from txt2hnd import text_to_handwritten

def main():
    st.title("Assignments Writer APP!!")
    title = st.text_input("Whats your Title?")
    n=st.slider("number of lines?",min_value=1,max_value=100)
    submit = st.button("write")
    if submit:
        data = wikipedia.summary(title,sentences=n)
        handwritten = text_to_handwritten(data)
        st.image("handwritten_text_page_1.png")


if __name__ == '__main__':
    main()