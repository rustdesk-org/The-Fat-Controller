use std::{
    sync::{Arc, Mutex},
    thread,
    time::Duration,
};
use tfc::{traits::*, Context, Error};

// `unicode_char('s')` should always type an `s` no matter what the keyboard
// layout is. `ascii_char(b's')` will press the key in the position of an `s` on
// a QWERTY keyboard. When using the QWERTY layout, this results in an `s` being
// typed. However, when using a different keyboard layout, pressing the `s` key
// might result in a different character being typed. For example, using Dvorak
// would result in an `o` being typed if the `s` key is pressed.

lazy_static::lazy_static! {
    static ref KBD_CONTEXT: Mutex<Context> = Mutex::new(Context::new().expect("error"));
}

fn main() -> Result<(), Error> {
    let delay = Duration::from_millis(50);

    // let mut ctx: Mutex<Context> = Mutex::new(Context::new().unwrap());

    // dbg!(ctx.key_map.get(&'A'));

    // for c in b' '..=b'~' {
    //     thread::sleep(delay);
    //     ctx.unicode_char(c as char)?;
    //     ctx.ascii_char(b' ')?;
    //     ctx.ascii_char(c)?;
    //     ctx.ascii_char(b'\n')?;
    // }

    let c = 'â'; // â
    KBD_CONTEXT.lock().unwrap().unicode_char_down(c as char)?;
    KBD_CONTEXT.lock().unwrap().unicode_char_up(c as char)?;
    // dbg!(KBD_CONTEXT.lock().unwrap().key_map.get(&c));

    Ok(())
}
