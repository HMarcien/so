mod api;
mod local_storage;
mod search;
// Exposed for benchmarking
pub mod scraper;

pub use api::{Answer, Id, Question};
pub use local_storage::LocalStorage;
pub use search::Search;
