# Poniden

Notch desktop bergaya Dynamic Island untuk **CachyOS dengan KDE Plasma di Wayland**. Arahkan kursor ke notch untuk melihat jam dan baterai. Klik untuk membuka panel, lalu klik roda gigi untuk membuka atau menutup pengaturan.

## Fitur

- Kontrol media lewat MPRIS, Pomodoro dengan alarm, Shelf untuk file, To-do, Catatan, dan pemantau sistem.
- Perkiraan jadwal salat offline untuk beberapa kota, termasuk Padang. Aktifkan pengingat di tab **Salat** untuk memutar azan Mekkah.
- Auto-hide saat jendela aktif dimaksimalkan atau ada aplikasi fullscreen di layar notch. Pengingat Pomodoro dan salat muncul di atas aplikasi.
- Tampilan notch, animasi mata, serta autostart yang bisa diatur.

## Menjalankan

Poniden memakai Python 3, PySide6/Qt 6.12 atau lebih baru, KDE Plasma 6 Wayland, LayerShellQt, dan PipeWire untuk suara. Pada CachyOS yang sudah diperbarui, paket yang diperlukan bisa dipasang dengan:

```bash
sudo pacman -S --needed pyside6 layer-shell-qt plasma-workspace pipewire-audio
```

```bash
git clone https://github.com/azlan07/Poniden.git
cd Poniden
bash poni.sh
```

Untuk mulai otomatis, buka menu ikon Poniden di tray dan pilih **Jalankan saat masuk KDE**. Pilih **Keluar** untuk menghentikan proses.

## Kredit dan lisensi

Dikembangkan oleh **utidev**. Poniden tumbuh dari sesi prototyping dan percakapan dengan **GPT-6.1 Sol**, lalu bentuk dan perilakunya disempurnakan lewat uji langsung di CachyOS.

Kode Poniden tersedia dengan [Lisensi MIT](LICENSE). Rekaman alarm dan azan punya lisensi Creative Commons masing-masing, dengan sumber dan atribusi di [Kredit audio](AUDIO.md).
