use std::collections::HashSet;

#[derive(Clone)]
struct Buffer<T> {
    pub data: Vec<T>,
    capacity: usize,
}

impl<T> Buffer<T> {
    fn new(capacity: usize) -> Self {
        Buffer {
            data: Vec::with_capacity(capacity),
            capacity,
        }
    }

    fn push(&mut self, item: T) {
        if self.data.len() == self.capacity {
            self.data.remove(0);
        }
        self.data.push(item);
    }
}

#[derive(Clone)]
pub struct StopWordHandler {
    pub stop_words: HashSet<Vec<u8>>,
    buffer: Buffer<u8>,
}

impl StopWordHandler {
    pub fn new(model: &dyn llm::Model, stop_words: &[String]) -> StopWordHandler {
        let tokenized_stop_words: HashSet<Vec<u8>> = stop_words
            .iter()
            .map(|word| {
                model
                    .vocabulary()
                    .tokenize(word, false)
                    .unwrap()
                    .iter()
                    .flat_map(|(encoding, _)| *encoding)
                    .copied()
                    .collect::<Vec<u8>>()
            })
            .collect();

        let capacity = tokenized_stop_words
            .iter()
            .map(|v| v.len())
            .max()
            .unwrap_or(0);

        StopWordHandler {
            stop_words: tokenized_stop_words,
            buffer: Buffer::new(capacity),
        }
    }

    pub fn process(&mut self, new_tokens: Vec<u8>) -> bool {
        for token in new_tokens {
            self.buffer.push(token);
            for i in 0..self.buffer.data.len() {
                let slice = self.buffer.data[i..].to_vec();
                if self.stop_words.contains(&slice) {
                    return true;
                }
            }
        }
        false
    }
}
