# Guía Completa: Re-firmar Firmware UNISOC con AVB2

## Estructura de tu Firmware

Tu dispositivo usa AVB2 (Android Verified Boot 2.0) con esta jerarquía:

```
vbmeta.img (raíz de confianza)
├── boot (SHA1: 54eda7333562e6fe6fcb9fa2a66afb3d5c09a94e)
├── dtbo (SHA1: 54eda7333562e6fe6fcb9fa2a66afb3d5c09a94e) [misma clave que boot]
├── recovery (SHA1: 0be51f630bc4555d14ab8a7f7eb10acc580d5d3f) [clave diferente]
├── vbmeta_system (SHA1: dc67561ffc74bddc5525f9c2cddf13375e685d13)
│   ├── system.img (dm-verity)
│   └── product.img (dm-verity)
├── vbmeta_vendor (SHA1: cccdbe264bc457f8c72b8e278fd391bdb0f4af5d)
│   └── vendor.img (dm-verity)
└── Otras particiones (socko, odmko, l_modem, l_ldsp, l_gdsp, pm_sys)
```

## Cambios Clave en los Scripts

### 1. sign_modified.sh

**Cambios principales:**
- Soporte para `vbmeta_system.img` y `vbmeta_vendor.img`
- Re-firma estas particiones usando `make_vbmeta_image` con `--include_descriptors_from_image`
- Preserva los descriptores hashtree de system/product y vendor

**Uso:**
```bash
./sign_modified.sh
```

### 2. sign_avb_enhanced.sh

**Mejoras:**
- Extrae automáticamente todas las propiedades (`Prop:`) de la imagen original
- Maneja correctamente el tamaño de partición
- Mejor logging del proceso

### 3. generate_vbmeta_with_chains.sh

**Propósito:**
Genera `vbmeta.img` con chain descriptors apuntando a todas las sub-particiones

**Características:**
- Chain descriptors para boot, dtbo, recovery
- Chain descriptors para vbmeta_system y vbmeta_vendor
- Soporte opcional para socko, odmko, modem partitions
- Usa las claves públicas correctas para cada partición

## Workflow de GitHub Actions

### Inputs necesarios:

1. **ZIP_URL**: URL del ZIP que debe contener:
   ```
   - splloader.bin o u-boot-spl-16k-sign.bin
   - uboot.bin
   - sml.bin
   - tos.bin o trustos.bin
   - teecfg.bin
   - boot.img o boot-sign.img
   - dtbo.img o dtbo-sign.img
   - recovery.img o recovery-sign.img
   - vbmeta.img o vbmeta-sign.img
   - vbmeta_system.img
   - vbmeta_vendor.img
   ```

2. **EXTRA_KEY_TREE_URL** (opcional): Repositorio con claves custom
3. **EXTRA_KEY_BRANCH** (opcional): Rama del repositorio de claves

### Output:

Archivo `resigned.zip` conteniendo:
```
output/
├── u-boot-spl-16k-sign.bin
├── uboot-sign.bin
├── sml-sign.bin
├── tos-sign.bin
├── teecfg-sign.bin
├── boot.img (con Magisk)
├── dtbo.img
├── recovery.img
├── vbmeta.img
├── vbmeta_system.img
└── vbmeta_vendor.img
```

## Consideraciones Importantes

### 1. System y Product NO se modifican

Las imágenes `system.img` y `product.img` **NO** están en el ZIP y **NO** se modifican. Solo se re-firma `vbmeta_system.img` que contiene los descriptores hashtree que apuntan a estas particiones.

### 2. Algoritmo NONE en system/product/vendor

Las imágenes individuales (`system.img`, `product.img`, `vendor.img`) muestran `Algorithm: NONE` porque:
- Son imágenes dm-verity sin firma AVB directa
- La firma está en sus respectivos vbmeta (vbmeta_system, vbmeta_vendor)
- Los descriptores hashtree validan la integridad
- vbmeta principal hace chain a vbmeta_system y vbmeta_vendor

### 3. Claves Públicas

Tu setup requiere **4 pares de claves diferentes**:

1. **rsa4096_boot.pem/.bin** - Para boot y dtbo
2. **rsa4096_recovery.pem/.bin** - Para recovery
3. **rsa4096_vbmeta_system.pem/.bin** - Para vbmeta_system
4. **rsa4096_vbmeta_vendor.pem/.bin** - Para vbmeta_vendor
5. **rsa4096_vbmeta.pem** - Para vbmeta principal

### 4. Rollback Indexes

Mantén los índices originales:
- boot: Location 1, Index 2
- recovery: Location 2, Index 2
- vbmeta_system: Location 3, Index 2
- vbmeta_vendor: Location 4, Index 2
- dtbo: Location 10, Index 2
- socko: Location 11
- odmko: Location 12

## Proceso de Firma Completo

1. **Bootloader** → Firma con sign_image_v2.sh
2. **boot.img** → Patch con Magisk + AVB footer
3. **dtbo.img** → AVB footer
4. **recovery.img** → AVB footer
5. **vbmeta_system.img** → Re-genera con descriptors de system/product
6. **vbmeta_vendor.img** → Re-genera con descriptors de vendor
7. **vbmeta.img** → Chain descriptors a todas las particiones

## Troubleshooting

### Error: "Public key mismatch"
- Verifica que uses las mismas claves públicas que el firmware original
- O usa claves custom y flasha todo el bootloader

### Error: "Verification failed"
- Asegúrate que vbmeta_system incluya los descriptores originales
- Verifica que los salts y digests no hayan cambiado

### Device no bootea
- Verifica que teecfg.bin esté presente (Android 10+)
- Confirma que los rollback indexes coincidan
- Puede requerir `fastboot erase userdata` si cambiaste vbmeta

## Comandos Útiles

### Verificar vbmeta
```bash
python avbtool.py info_image --image vbmeta.img
```

### Ver chain descriptors
```bash
python avbtool.py info_image --image vbmeta.img | grep -A3 "Chain Partition"
```

### Extraer clave pública de PEM
```bash
python avbtool.py extract_public_key --key rsa4096_boot.pem --output boot_pub.bin
```

### Calcular SHA1 de clave pública
```bash
sha1sum boot_pub.bin
```

## Referencias

- [Android AVB Documentation](https://android.googlesource.com/platform/external/avb/)
- [UNISOC Sign Image Tools](https://github.com/TomKing062/vendor_sprd_proprietories-source_packimage)
- [Magisk Documentation](https://topjohnwu.github.io/Magisk/)
