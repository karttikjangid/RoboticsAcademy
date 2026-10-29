# Podman images removed for disk space

Captured before removal with `podman images --no-trunc --format json`. Size is Podman reported virtual image size in bytes. IDs are full IDs. Images were not attached to containers at capture time (`Containers: 0` for every record).

| Image ID | Repository tags | Size (bytes) | Size (GiB) |
| --- | --- | ---: | ---: |
| `01c20a1642991429ed094028bff59a975efcc625df71c35283b2b9e5e372c9b5` | docker.io/jderobot/robotics-database:latest | 495570903 | 0.46 |
| `0c0cce9b04f4223b0a1ff5c4fa1f6d13dfe2472d818b4ad1e698196dea465a02` | docker.io/jderobot/robotics-academy:latest | 12450138474 | 11.60 |
| `2d02c9456d37f78e1e9bea1216646f8290519574f69cfc79001308d7b9695447` | (untagged) | 495439835 | 0.46 |
| `33ed5ef90e835c40007b658b2d7cb1354b282bffcb53feceb305e9feff1d98e1` | docker.io/library/node:20 | 1119538401 | 1.04 |
| `8f32386ab20d3b8f9e5b7b453dcc8cdddf1eac1f6c5210bdd2fc0d0ae5135659` | localhost/jderobot/robotics-applications:dependencies-humble, localhost/deps-podman-test:latest | 10909352758 | 10.16 |
| `a6ebe47bce023ba59f58029ff218c0adc83f641e6c3faa4963a1108835093325` | localhost/jderobot/robotics-academy:test, localhost/academy-podman-test:latest | 12092406273 | 11.26 |
| `de7345b16e942e22044c6ba053020ec85ae879984860a9918517d54eb6cef851` | docker.io/library/ubuntu:latest | 111578664 | 0.10 |
| `ea47434d58c317ad0f29452c2183dc9fc8dce4b18ae44cc3fcd96c0969d96399` | (untagged) | 3534315552 | 3.29 |
| `fa3b3c2b9c91ea54d48da8d150460d1d609db14e0219c4e3a0b84678830dbb1c` | docker.io/nvidia/opengl:1.2-glvnd-runtime-ubuntu22.04 | 485578203 | 0.45 |

Unique image IDs logged: 9.
Sum of reported virtual sizes: 41693919063 bytes (38.83 GiB). This sum is not expected disk space reclaimed because image layers can be shared.

Pre-removal `podman system df`: 116 images, 0 active, 28.7 GB reported, 28.7 GB reclaimable; 0 containers, 0 B; 38 volumes, 2.074 GB reported, 2.074 GB reclaimable. Images are separate from volumes.
