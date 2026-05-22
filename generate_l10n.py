import json
import os

languages = {
    'en': 'English', 'es': 'Español', 'fr': 'Français', 'de': 'Deutsch',
    'it': 'Italiano', 'pt': 'Português', 'ru': 'Русский', 'zh': '简体中文',
    'zh_Hant': '繁體中文', 'ja': '日本語', 'ko': '한국어', 'hi': 'हिन्दी',
    'ar': 'العربية', 'th': 'ไทย', 'vi': 'Tiếng Việt', 'nl': 'Nederlands',
    'sv': 'Svenska', 'no': 'Norsk', 'da': 'Dansk', 'fi': 'Suomi',
    'pl': 'Polski', 'cs': 'Čeština', 'hu': 'Magyar', 'ro': 'Română',
    'el': 'Ελληνικά', 'tr': 'Türkçe', 'id': 'Bahasa Indonesia', 'ms': 'Bahasa Melayu',
    'fil': 'Filipino', 'sw': 'Kiswahili', 'ur': 'اردو', 'bn': 'বাংলা'
}

core_translations = {
    'home': {'en': 'Home', 'es': 'Inicio', 'fr': 'Accueil', 'de': 'Startseite', 'it': 'Home', 'pt': 'Início', 'ru': 'Главная', 'zh': '首页', 'zh_Hant': '首頁', 'ja': 'ホーム', 'ko': '홈', 'hi': 'होम', 'ar': 'الرئيسية', 'th': 'หน้าแรก', 'vi': 'Trang chủ', 'nl': 'Home', 'sv': 'Hem', 'no': 'Hjem', 'da': 'Hjem', 'fi': 'Koti', 'pl': 'Główna', 'cs': 'Domů', 'hu': 'Kezdőlap', 'ro': 'Acasă', 'el': 'Αρχική', 'tr': 'Ana Sayfa', 'id': 'Beranda', 'ms': 'Utama', 'fil': 'Home', 'sw': 'Nyumbani', 'ur': 'ہوم', 'bn': 'হোম'},
    'explore': {'en': 'Explore', 'es': 'Explorar', 'fr': 'Explorer', 'de': 'Entdecken', 'it': 'Esplora', 'pt': 'Explorar', 'ru': 'Исследовать', 'zh': '发现', 'zh_Hant': '發現', 'ja': '見つける', 'ko': '탐색', 'hi': 'खोजें', 'ar': 'استكشاف', 'th': 'สำรวจ', 'vi': 'Khám phá', 'nl': 'Ontdekken', 'sv': 'Utforska', 'no': 'Utforsk', 'da': 'Udforsk', 'fi': 'Tutki', 'pl': 'Odkrywaj', 'cs': 'Prozkoumat', 'hu': 'Felfedezés', 'ro': 'Explorează', 'el': 'Εξερεύνηση', 'tr': 'Keşfet', 'id': 'Jelajahi', 'ms': 'Teroka', 'fil': 'I-explore', 'sw': 'Gundua', 'ur': 'دریافت کریں', 'bn': 'অন্বেষণ'},
    'settings': {'en': 'Settings', 'es': 'Ajustes', 'fr': 'Paramètres', 'de': 'Einstellungen', 'it': 'Impostazioni', 'pt': 'Configurações', 'ru': 'Настройки', 'zh': '设置', 'zh_Hant': '設置', 'ja': '設定', 'ko': '설정', 'hi': 'सेटिंग्स', 'ar': 'الإعدادات', 'th': 'การตั้งค่า', 'vi': 'Cài đặt', 'nl': 'Instellingen', 'sv': 'Inställningar', 'no': 'Innstillinger', 'da': 'Indstillinger', 'fi': 'Asetukset', 'pl': 'Ustawienia', 'cs': 'Nastavení', 'hu': 'Beállítások', 'ro': 'Setări', 'el': 'Ρυθμίσεις', 'tr': 'Ayarlar', 'id': 'Pengaturan', 'ms': 'Tetapan', 'fil': 'Mga Setting', 'sw': 'Mipangilio', 'ur': 'ترجیحات', 'bn': 'সেটিংস'},
    'language': {'en': 'Language', 'es': 'Idioma', 'fr': 'Langue', 'de': 'Sprache', 'it': 'Lingua', 'pt': 'Idioma', 'ru': 'Язык', 'zh': '语言', 'zh_Hant': '語言', 'ja': '言語', 'ko': '언어', 'hi': 'भाषा', 'ar': 'اللغة', 'th': 'ภาษา', 'vi': 'Ngôn ngữ', 'nl': 'Taal', 'sv': 'Språk', 'no': 'Språk', 'da': 'Sprog', 'fi': 'Kieli', 'pl': 'Język', 'cs': 'Jazyk', 'hu': 'Nyelv', 'ro': 'Limbă', 'el': 'Γλώσσα', 'tr': 'Dil', 'id': 'Bahasa', 'ms': 'Bahasa', 'fil': 'Wika', 'sw': 'Lugha', 'ur': 'زبان', 'bn': 'ভাষা'},
    'profile': {'en': 'Profile', 'es': 'Perfil', 'fr': 'Profil', 'de': 'Profil', 'it': 'Profilo', 'pt': 'Perfil', 'ru': 'Профиль', 'zh': '个人资料', 'zh_Hant': '個人資料', 'ja': 'プロフィール', 'ko': '프로필', 'hi': 'प्रोफ़ाइल', 'ar': 'الملف الشخصي', 'th': 'โปรไฟล์', 'vi': 'Hồ sơ', 'nl': 'Profiel', 'sv': 'Profil', 'no': 'Profil', 'da': 'Profil', 'fi': 'Profiili', 'pl': 'Profil', 'cs': 'Profil', 'hu': 'Profil', 'ro': 'Profil', 'el': 'Προφίλ', 'tr': 'Profil', 'id': 'Profil', 'ms': 'Profil', 'fil': 'Profile', 'sw': 'Wasifu', 'ur': 'پروفائل', 'bn': 'প্রোফাইল'},
    'logout': {'en': 'Logout', 'es': 'Cerrar sesión', 'fr': 'Déconnexion', 'de': 'Abmelden', 'it': 'Logout', 'pt': 'Sair', 'ru': 'Выйти', 'zh': '登出', 'zh_Hant': '登出', 'ja': 'ログアウト', 'ko': '로그아웃', 'hi': 'लॉगआउट', 'ar': 'تسجيل الخروج', 'th': 'ออกจากระบบ', 'vi': 'Đăng xuất', 'nl': 'Uitloggen', 'sv': 'Logga ut', 'no': 'Logg ut', 'da': 'Log ud', 'fi': 'Kirjaudu ulos', 'pl': 'Wyloguj', 'cs': 'Odhlásit se', 'hu': 'Kijelentkezés', 'ro': 'Deconectare', 'el': 'Αποσύνδεση', 'tr': 'Çıkış Yap', 'id': 'Keluar', 'ms': 'Log keluar', 'fil': 'Mag-logout', 'sw': 'Ondoka', 'ur': 'لاگ آؤٹ', 'bn': 'লগআউট'},
    'cancel': {'en': 'Cancel', 'es': 'Cancelar', 'fr': 'Annuler', 'de': 'Abbrechen', 'it': 'Annulla', 'pt': 'Cancelar', 'ru': 'Отмена', 'zh': '取消', 'zh_Hant': '取消', 'ja': 'キャンセル', 'ko': '취소', 'hi': 'रद्द करें', 'ar': 'إلغاء', 'th': 'ยกเลิก', 'vi': 'Hủy', 'nl': 'Annuleren', 'sv': 'Avbryt', 'no': 'Avbryt', 'da': 'Annuller', 'fi': 'Peruuta', 'pl': 'Anuluj', 'cs': 'Zrušit', 'hu': 'Mégse', 'ro': 'Anulează', 'el': 'Ακύρωση', 'tr': 'İptal', 'id': 'Batal', 'ms': 'Batal', 'fil': 'Kanselahin', 'sw': 'Ghairi', 'ur': 'منسوخ کریں', 'bn': 'বাতিল'},
    'ok': {'en': 'OK', 'es': 'Aceptar', 'fr': 'OK', 'de': 'OK', 'it': 'OK', 'pt': 'OK', 'ru': 'ОК', 'zh': '确定', 'zh_Hant': '確定', 'ja': 'OK', 'ko': '확인', 'hi': 'ठीक है', 'ar': 'موافق', 'th': 'ตกลง', 'vi': 'OK', 'nl': 'OK', 'sv': 'OK', 'no': 'OK', 'da': 'OK', 'fi': 'OK', 'pl': 'OK', 'cs': 'OK', 'hu': 'OK', 'ro': 'OK', 'el': 'OK', 'tr': 'Tamam', 'id': 'OK', 'ms': 'OK', 'fil': 'OK', 'sw': 'Sawa', 'ur': 'ٹھیک ہے', 'bn': 'ঠিক আছে'},
    'search': {'en': 'Search', 'es': 'Buscar', 'fr': 'Rechercher', 'de': 'Suche', 'it': 'Cerca', 'pt': 'Buscar', 'ru': 'Поиск', 'zh': '搜索', 'zh_Hant': '搜索', 'ja': '検索', 'ko': '검색', 'hi': 'खोजें', 'ar': 'بحث', 'th': 'ค้นหา', 'vi': 'Tìm kiếm', 'nl': 'Zoeken', 'sv': 'Sök', 'no': 'Søk', 'da': 'Søg', 'fi': 'Hae', 'pl': 'Szukaj', 'cs': 'Hledat', 'hu': 'Keresés', 'ro': 'Caută', 'el': 'Αναζήτηση', 'tr': 'Ara', 'id': 'Cari', 'ms': 'Cari', 'fil': 'Maghanap', 'sw': 'Tafuta', 'ur': 'تلاش کریں', 'bn': 'অনুসন্ধান'},
    'following': {'en': 'Following', 'es': 'Siguiendo', 'fr': 'Abonnements', 'de': 'Folge ich', 'it': 'Seguiti', 'pt': 'Seguindo', 'ru': 'Подписки', 'zh': '关注中', 'zh_Hant': '關注中', 'ja': 'フォロー中', 'ko': '팔로잉', 'hi': 'फ़ॉλο कर रहे हैं', 'ar': 'متابعون', 'th': 'กำลังติดตาม', 'vi': 'Đang theo dõi', 'nl': 'Volgend', 'sv': 'Följer', 'no': 'Følger', 'da': 'Følger', 'fi': 'Seurataan', 'pl': 'Obserwowani', 'cs': 'Sleduji', 'hu': 'Követés', 'ro': 'Urmărești', 'el': 'Ακολουθείτε', 'tr': 'Takip Edilen', 'id': 'Mengikuti', 'ms': 'Mengikuti', 'fil': 'Sinusundan', 'sw': 'Unahofia', 'ur': 'فالو کر رہے ہیں', 'bn': 'অনুসরণ করছেন'},
    'followers': {'en': 'Followers', 'es': 'Seguidores', 'fr': 'Abonnés', 'de': 'Follower', 'it': 'Follower', 'pt': 'Seguidores', 'ru': 'Подписчики', 'zh': '粉丝', 'zh_Hant': '粉絲', 'ja': 'フォロワー', 'ko': '팔로워', 'hi': 'फ़ॉलोअर्स', 'ar': 'المتابعون', 'th': 'ผู้ติดตาม', 'vi': 'Người theo dõi', 'nl': 'Volgers', 'sv': 'Följare', 'no': 'Følgere', 'da': 'Følgere', 'fi': 'Seuraajat', 'pl': 'Obserwujący', 'cs': 'Sledující', 'hu': 'Követők', 'ro': 'Urmăritori', 'el': 'Ακόλουθοι', 'tr': 'Takipçiler', 'id': 'Pengikut', 'ms': 'Pengikut', 'fil': 'Mga Follower', 'sw': 'Wafuasi', 'ur': 'فالورز', 'bn': 'অনুসারী'},
    'posts': {'en': 'Posts', 'es': 'Publicaciones', 'fr': 'Publications', 'de': 'Beiträge', 'it': 'Post', 'pt': 'Publicações', 'ru': 'Посты', 'zh': '帖子', 'zh_Hant': '帖子', 'ja': '投稿', 'ko': '게시물', 'hi': 'पोस्ट', 'ar': 'منشورات', 'th': 'โพสต์', 'vi': 'Bài viết', 'nl': 'Berichten', 'sv': 'Inlägg', 'no': 'Innlegg', 'da': 'Indlæg', 'fi': 'Julkaisut', 'pl': 'Posty', 'cs': 'Příspěvky', 'hu': 'Posztok', 'ro': 'Postări', 'el': 'Δημοσιεύσεις', 'tr': 'Gönderiler', 'id': 'Postingan', 'ms': 'Siaran', 'fil': 'Mga Post', 'sw': 'Machapisho', 'ur': 'پوسٹس', 'bn': 'পোস্ট'},
    'editProfile': {'en': 'Edit Profile', 'es': 'Editar perfil', 'fr': 'Modifier le profil', 'de': 'Profil bearbeiten', 'it': 'Modifica profilo', 'pt': 'Editar perfil', 'ru': 'Ред. профиль', 'zh': '编辑资料', 'zh_Hant': '編輯資料', 'ja': 'プロフィール編集', 'ko': '프로필 편집', 'hi': 'प्रोफ़ाइल बदलें', 'ar': 'تعديل الملف', 'th': 'แก้ไขโปรไฟล์', 'vi': 'Sửa hồ sơ', 'nl': 'Profiel bewerken', 'sv': 'Redigera profil', 'no': 'Rediger profil', 'da': 'Rediger profil', 'fi': 'Muokkaa profiilia', 'pl': 'Edytuj profil', 'cs': 'Upravit profil', 'hu': 'Profil szerkesztése', 'ro': 'Editează profilul', 'el': 'Επεξεργασία προφίλ', 'tr': 'Profili Düzenle', 'id': 'Edit Profil', 'ms': 'Sunting Profil', 'fil': 'I-edit ang Profile', 'sw': 'Hariri Wasifu', 'ur': 'پروفائل تبدیل کریں', 'bn': 'প্রোফাইল সম্পাদনা'},
    'like': {'en': 'Like', 'es': 'Me gusta', 'fr': 'J\'aime', 'de': 'Gefällt mir', 'it': 'Mi piace', 'pt': 'Curtir', 'ru': 'Нравится', 'zh': '点赞', 'zh_Hant': '點讚', 'ja': 'いいね', 'ko': '좋아요', 'hi': 'पसंद करें', 'ar': 'أعجبني', 'th': 'ถูกใจ', 'vi': 'Thích', 'nl': 'Leuk vinden', 'sv': 'Gilla', 'no': 'Lik', 'da': 'Synes godt om', 'fi': 'Tykkää', 'pl': 'Lubię to', 'cs': 'To se mi líbí', 'hu': 'Tetszik', 'ro': 'Îmi place', 'el': 'Μου αρέσει', 'tr': 'Beğen', 'id': 'Suka', 'ms': 'Suka', 'fil': 'I-like', 'sw': 'Penda', 'ur': 'پسند کریں', 'bn': 'পছন্দ করুন'},
    'comment': {'en': 'Comment', 'es': 'Comentar', 'fr': 'Commenter', 'de': 'Kommentieren', 'it': 'Commenta', 'pt': 'Comentar', 'ru': 'Комментировать', 'zh': '评论', 'zh_Hant': '評論', 'ja': 'コメント', 'ko': '댓글', 'hi': 'टिप्पणी करें', 'ar': 'تعليق', 'th': 'ความคิดเห็น', 'vi': 'Bình luận', 'nl': 'Reageren', 'sv': 'Kommentera', 'no': 'Kommenter', 'da': 'Kommenter', 'fi': 'Kommentoi', 'pl': 'Komentuj', 'cs': 'Komentovat', 'hu': 'Hozzászólás', 'ro': 'Comentează', 'el': 'Σχόλιο', 'tr': 'Yorum Yap', 'id': 'Komentar', 'ms': 'Komen', 'fil': 'Mag-comment', 'sw': 'Toa maoni', 'ur': 'تبصرہ کریں', 'bn': 'মন্তব্য করুন'},
    'share': {'en': 'Share', 'es': 'Compartir', 'fr': 'Partager', 'de': 'Teilen', 'it': 'Condividi', 'pt': 'Compartilhar', 'ru': 'Поделиться', 'zh': '分享', 'zh_Hant': '分享', 'ja': '共有', 'ko': '공유', 'hi': 'साझा करें', 'ar': 'مشاركة', 'th': 'แชร์', 'vi': 'Chia sẻ', 'nl': 'Delen', 'sv': 'Dela', 'no': 'Del', 'da': 'Del', 'fi': 'Jaa', 'pl': 'Udostępnij', 'cs': 'Sdílet', 'hu': 'Megosztás', 'ro': 'Distribuie', 'el': 'Κοινοποίηση', 'tr': 'Paylaş', 'id': 'Bagikan', 'ms': 'Kongsi', 'fil': 'I-share', 'sw': 'Shiriki', 'ur': 'شیئر کریں', 'bn': 'শেয়ার করুন'},
    'save': {'en': 'Save', 'es': 'Guardar', 'fr': 'Enregistrer', 'de': 'Speichern', 'it': 'Salva', 'pt': 'Salvar', 'ru': 'Сохранить', 'zh': '保存', 'zh_Hant': '保存', 'ja': '保存', 'ko': '저장', 'hi': 'सहेजें', 'ar': 'حفظ', 'th': 'บันทึก', 'vi': 'Lưu', 'nl': 'Opslaan', 'sv': 'Spara', 'no': 'Lagre', 'da': 'Gem', 'fi': 'Tallenna', 'pl': 'Zapisz', 'cs': 'Uložit', 'hu': 'Mentés', 'ro': 'Salvează', 'el': 'Αποθήκευση', 'tr': 'Kaydet', 'id': 'Simpan', 'ms': 'Simpan', 'fil': 'I-save', 'sw': 'Hifadhi', 'ur': 'محفوظ کریں', 'bn': 'সংরক্ষণ করুন'},
    'delete': {'en': 'Delete', 'es': 'Eliminar', 'fr': 'Supprimer', 'de': 'Löschen', 'it': 'Elimina', 'pt': 'Excluir', 'ru': 'Удалить', 'zh': '删除', 'zh_Hant': '刪除', 'ja': '削除', 'ko': '삭제', 'hi': 'हटाएं', 'ar': 'حذف', 'th': 'ลบ', 'vi': 'Xóa', 'nl': 'Verwijderen', 'sv': 'Radera', 'no': 'Slett', 'da': 'Slet', 'fi': 'Poista', 'pl': 'Usuń', 'cs': 'Smazat', 'hu': 'Törlés', 'ro': 'Șterge', 'el': 'Διαγραφή', 'tr': 'Sil', 'id': 'Hapus', 'ms': 'Padam', 'fil': 'I-delete', 'sw': 'Futa', 'ur': 'حذف کریں', 'bn': 'মুছে ফেলুন'},
    'edit': {'en': 'Edit', 'es': 'Editar', 'fr': 'Modifier', 'de': 'Bearbeiten', 'it': 'Modifica', 'pt': 'Editar', 'ru': 'Редактировать', 'zh': '编辑', 'zh_Hant': '編輯', 'ja': '編集', 'ko': '편집', 'hi': 'बदलें', 'ar': 'تعديل', 'th': 'แก้ไข', 'vi': 'Chỉnh sửa', 'nl': 'Bewerken', 'sv': 'Redigera', 'no': 'Rediger', 'da': 'Rediger', 'fi': 'Muokkaa', 'pl': 'Edytuj', 'cs': 'Upravit', 'hu': 'Szerkesztés', 'ro': 'Editează', 'el': 'Επεξεργασία', 'tr': 'Düzenle', 'id': 'Edit', 'ms': 'Sunting', 'fil': 'I-edit', 'sw': 'Hariri', 'ur': 'ترمیم کریں', 'bn': 'সম্পাদনা করুন'},
    'searchPlaceholder': {'en': 'Search...', 'es': 'Buscar...', 'fr': 'Rechercher...', 'de': 'Suche...', 'it': 'Cerca...', 'pt': 'Buscar...', 'ru': 'Поиск...', 'zh': '搜索...', 'zh_Hant': '搜索...', 'ja': '検索...', 'ko': '검색...', 'hi': 'खोजें...', 'ar': 'بحث...', 'th': 'ค้นหา...', 'vi': 'Tìm kiếm...', 'nl': 'Zoeken...', 'sv': 'Sök...', 'no': 'Søk...', 'da': 'Søg...', 'fi': 'Hae...', 'pl': 'Szukaj...', 'cs': 'Hledat...', 'hu': 'Keresés...', 'ro': 'Caută...', 'el': 'Αναζήτηση...', 'tr': 'Ara...', 'id': 'Cari...', 'ms': 'Cari...', 'fil': 'Maghanap...', 'sw': 'Tafuta...', 'ur': 'تلاش کریں...', 'bn': 'অনুসন্ধান...'},
    'deletePost': {'en': 'Delete Post', 'es': 'Eliminar publicación', 'fr': 'Supprimer le post', 'de': 'Beitrag löschen', 'it': 'Elimina post', 'pt': 'Excluir post', 'ru': 'Удалить пост', 'zh': '删除帖子', 'zh_Hant': '刪除帖子', 'ja': '投稿を削除', 'ko': '게시물 삭제', 'hi': 'पोस्ट हटाएं', 'ar': 'حذف المنشور', 'th': 'ลบโพสต์', 'vi': 'Xóa bài viết', 'nl': 'Bericht verwijderen', 'sv': 'Radera inlägg', 'no': 'Slett innlegg', 'da': 'Slett indlæg', 'fi': 'Poista julkaisu', 'pl': 'Usuń post', 'cs': 'Smazat příspěvek', 'hu': 'Poszt törlése', 'ro': 'Șterge postarea', 'el': 'Διαγραφή δημοσίευσης', 'tr': 'Gönderiyi Sil', 'id': 'Hapus Postingan', 'ms': 'Padam Siaran', 'fil': 'I-delete ang Post', 'sw': 'Futa Chapisho', 'ur': 'پوسٹ حذف کریں', 'bn': 'পোস্ট মুছে ফেলুন'},
    'deletePostConfirm': {'en': 'Are you sure you want to delete this post?', 'es': '¿Estás seguro de que quieres eliminar esta publicación?', 'fr': 'Êtes-vous sûr de vouloir supprimer ce post ?', 'de': 'Möchten Sie diesen Beitrag wirklich löschen?', 'it': 'Sei sicuro di voler eliminare questo post?', 'pt': 'Tem certeza de que deseja excluir este post?', 'ru': 'Вы уверены, что хотите удалить этот пост?', 'zh': '您确定要删除此帖子吗？', 'zh_Hant': '您確定要刪除此帖子嗎？', 'ja': 'この投稿を削除してもよろしいですか？', 'ko': '이 게시물을 삭제하시겠습니까?', 'hi': 'क्या आप वाकई इस पोस्ट को हटाना चाहते हैं?', 'ar': 'هل أنت متأكد من حذف هذا المنشور؟', 'th': 'คุณแน่ใจหรือไม่ว่าต้องการลบโพสต์นี้?', 'vi': 'Bạn có chắc chắn muốn xóa bài viết này không?', 'nl': 'Weet je zeker dat je dit bericht wilt verwijderen?', 'sv': 'Är du säker på att du vill radera detta inlägg?', 'no': 'Er du sikker på at du vil slette dette innlegget?', 'da': 'Er du sikker på, at du vil slette dette indlæg?', 'fi': 'Haluatko varmasti poistaa tämän julkaisun?', 'pl': 'Czy na pewno chcesz usunąć ten post?', 'cs': 'Opravdu chcete smazat tento příspěvek?', 'hu': 'Biztosan törölni szeretné ezt a posztot?', 'ro': 'Ești sigur că vrei să ștergi această postare?', 'el': 'Είστε σίγουροι ότι θέλετε να διαγράψετε αυτή τη δημοσίευση;', 'tr': 'Bu gönderiyi silmek istediğinizden emin misiniz?', 'id': 'Apakah Anda yakin ingin menghapus postingan ini?', 'ms': 'Adakah anda pasti mahu memadam siaran ini?', 'fil': 'Sigurado ka bang gusto mong i-delete ang post na ito?', 'sw': 'Je, una uhakika unataka kufuta chapisho hili?', 'ur': 'کیا آپ واقعی اس پوسٹ کو حذف کرنا چاہتے ہیں؟', 'bn': 'আপনি কি নিশ্চিত যে আপনি এই পোস্টটি মুছে ফেলতে চান?'},
    'you': {'en': 'You', 'es': 'Tú', 'fr': 'Vous', 'de': 'Du', 'it': 'Tu', 'pt': 'Você', 'ru': 'Вы', 'zh': '您', 'zh_Hant': '您', 'ja': 'あなた', 'ko': '당신', 'hi': 'आप', 'ar': 'أنت', 'th': 'คุณ', 'vi': 'Bạn', 'nl': 'Jij', 'sv': 'Du', 'no': 'Du', 'da': 'Du', 'fi': 'Sinä', 'pl': 'Ty', 'cs': 'Vy', 'hu': 'Te', 'ro': 'Tu', 'el': 'Εσείς', 'tr': 'Siz', 'id': 'Anda', 'ms': 'Anda', 'fil': 'Ikaw', 'sw': 'Wewe', 'ur': 'آپ', 'bn': 'আপনি'},
    'unknown': {'en': 'Unknown', 'es': 'Desconocido', 'fr': 'Inconnu', 'de': 'Unbekannt', 'it': 'Sconosciuto', 'pt': 'Desconhecido', 'ru': 'Неизвестно', 'zh': '未知', 'zh_Hant': '未知', 'ja': '不明', 'ko': '알 수 없음', 'hi': 'अज्ञात', 'ar': 'الرئيسية', 'th': 'ไม่ทราบ', 'vi': 'Không xác định', 'nl': 'Onbekend', 'sv': 'Okänd', 'no': 'Ukjent', 'da': 'Ukendt', 'fi': 'Tuntematon', 'pl': 'Nieznany', 'cs': 'Neznámý', 'hu': 'Ismeretlen', 'ro': 'Necunoscut', 'el': 'Άγνωστο', 'tr': 'Bilinmiyor', 'id': 'Tidak Diketahui', 'ms': 'Tidak Diketahui', 'fil': 'Hindi Alam', 'sw': 'Haijulikani', 'ur': 'نامعلوم', 'bn': 'অজানা'},
    'reels': {'en': 'Reels', 'es': 'Reels', 'fr': 'Reels', 'de': 'Reels', 'it': 'Reels', 'pt': 'Reels', 'ru': 'Reels', 'zh': '短视频', 'zh_Hant': '短視頻', 'ja': 'リール', 'ko': '릴스', 'hi': 'रील्स', 'ar': 'ريلز', 'th': 'Reels', 'vi': 'Reels', 'tr': 'Reels', 'ur': 'رییلز'},
    'live': {'en': 'Live', 'es': 'En vivo', 'fr': 'Direct', 'de': 'Live', 'it': 'Dal vivo', 'pt': 'Ao vivo', 'ru': 'Live', 'zh': '直播', 'zh_Hant': '直播', 'ja': 'ライブ', 'ko': '라이브', 'hi': 'लाइव', 'ar': 'مباشر', 'th': 'ไลฟ์', 'vi': 'Trực tiếp', 'tr': 'Canlı', 'ur': 'لائیو'},
    'add': {'en': 'Add', 'es': 'Añadir', 'fr': 'Ajouter', 'de': 'Hinzufügen', 'it': 'Aggiungi', 'pt': 'Adicionar', 'ru': 'Добавить', 'zh': '添加', 'zh_Hant': '添加', 'ja': '追加', 'ko': '추가', 'hi': 'जोड़ें', 'ar': 'إضافة', 'th': 'เพิ่ม', 'vi': 'Thêm', 'tr': 'Ekle', 'ur': 'شامل کریں'},
    'notifications': {'en': 'Notifications', 'es': 'Notificaciones', 'fr': 'Notifications', 'de': 'Benachrichtigungen', 'it': 'Notifiche', 'pt': 'Notificações', 'ru': 'Уведомления', 'zh': '通知', 'zh_Hant': '通知', 'ja': '通知', 'ko': '알림', 'hi': 'सूचनाएं', 'ar': 'الإشعارات', 'th': 'การแจ้งเตือน', 'vi': 'Thông báo', 'tr': 'Bildirimler', 'ur': 'اطلاعات'},
    'message': {'en': 'message', 'es': 'mensaje', 'fr': 'message', 'de': 'Nachricht', 'it': 'messaggio', 'pt': 'mensagem', 'ru': 'сообщение', 'zh': '消息', 'zh_Hant': '消息', 'ja': 'メッセージ', 'ko': '메시지', 'hi': 'संदेश', 'ar': 'رسالة', 'th': 'ข้อความ', 'vi': 'tin nhắn', 'tr': 'mesaj', 'ur': 'پیغام'},
    'follow': {'en': 'follow', 'es': 'seguir', 'fr': 'suivre', 'de': 'folgen', 'it': 'segui', 'pt': 'seguir', 'ru': 'подписаться', 'zh': '关注', 'zh_Hant': '關注', 'ja': 'フォロー', 'ko': '팔로우', 'hi': 'फ़ॉलो करें', 'ar': 'متابعة', 'th': 'ติดตาม', 'vi': 'theo dõi', 'tr': 'takip et', 'ur': 'فالو کریں'},
    'unfollow': {'en': 'unfollow', 'es': 'dejar de seguir', 'fr': 'se désabonner', 'de': 'nicht mehr folgen', 'it': 'non seguire più', 'pt': 'deixar de seguir', 'ru': 'отписаться', 'zh': '取消关注', 'zh_Hant': '取消關注', 'ja': 'フォロー解除', 'ko': '언팔로우', 'hi': 'अनफ़ॉलो करें', 'ar': 'إلغاء المتابعة', 'th': 'เลิกติดตาม', 'vi': 'bỏ theo dõi', 'tr': 'takibi bırak', 'ur': 'ان فالو کریں'},
    'send': {'en': 'send', 'es': 'enviar', 'fr': 'envoyer', 'de': 'senden', 'it': 'invia', 'pt': 'enviar', 'ru': 'отправить', 'zh': '发送', 'zh_Hant': '發送', 'ja': '送信', 'ko': '보내기', 'hi': 'भेजें', 'ar': 'إرسال', 'th': 'ส่ง', 'vi': 'gửi', 'tr': 'gönder', 'ur': 'بھجیں'},
    'reply': {'en': 'reply', 'es': 'responder', 'fr': 'répondre', 'de': 'antworten', 'it': 'rispondi', 'pt': 'responder', 'ru': 'ответить', 'zh': '回复', 'zh_Hant': '回覆', 'ja': '返信', 'ko': '답장', 'hi': 'जवाब दें', 'ar': 'رد', 'th': 'ตอบกลับ', 'vi': 'trả lời', 'tr': 'yanıtla', 'ur': 'جواب دیں'},
    'wallet': {'en': 'Wallet', 'es': 'Billetera', 'fr': 'Portefeuille', 'de': 'Brieftasche', 'it': 'Portafoglio', 'pt': 'Carteira', 'ru': 'Кошелек', 'zh': '钱包', 'zh_Hant': '錢包', 'ja': 'ウォレット', 'ko': '지갑', 'hi': 'वॉलेट', 'ar': 'المحفظة', 'th': 'กระเป๋าเงิน', 'vi': 'Ví', 'tr': 'Cüzdan', 'ur': 'والٹ'},
    'openFullPdf': {'en': 'Open Full PDF', 'es': 'Abrir PDF completo', 'fr': 'Ouvrir le PDF complet', 'de': 'Vollständiges PDF öffnen', 'it': 'Apri PDF completo', 'pt': 'Abrir PDF completo', 'ru': 'Открыть полный PDF', 'zh': '打开完整PDF', 'zh_Hant': '打開完整PDF', 'ja': '全文PDFを開く', 'ko': '전체 PDF 열기', 'hi': 'पूरा पीडीएफ खोलें', 'ar': 'فتح ملف PDF بالكامل', 'th': 'เปิด PDF ฉบับเต็ม', 'vi': 'Mở toàn bộ PDF', 'tr': 'Tam PDF\'i Aç', 'ur': 'مکمل پی ڈی ایف کھولیں'},
    'becomeCreator': {
        'en': 'Become Creator', 
        'es': 'Conviértete en creador',
        'tr': 'İçerik Üreticisi Ol',
        'hi': 'क्रिएटर बनें',
        'ur': 'کرئیٹر بنیں',
        'vi': 'Trở thành người sáng tạo',
        'zh': '成为创作者',
        'zh_Hant': '成為創作者',
        'fr': 'Devenir créateur',
        'de': 'Creator werden'
    },
    'becomeCreatorSubtitle': {
        'en': 'Join our community and start earning',
        'es': 'Únete a nuestra comunidad y empieza a ganar',
        'tr': 'Topluluğumuza katılın ve kazanmaya başlayın',
        'hi': 'हमारे समुदाय में शामिल हों और कमाई शुरू करें',
        'ur': 'ہماری کمیونٹی میں شامل ہوں اور کمانا شروع کریں',
        'vi': 'Tham gia cộng đồng và bắt đầu kiếm tiền',
        'zh': '加入我们的社区并开始赚钱',
        'zh_Hant': '加入我們的社區並開始賺錢',
        'fr': 'Rejoignez notre communauté et commencez à gagner',
        'de': 'Tritt unserer Community bei und fange an zu verdienen'
    },
    'connections': {'en': 'Connections', 'es': 'Conexiones', 'fr': 'Connexions', 'de': 'Verbindungen', 'it': 'Connessioni', 'pt': 'Conexões', 'ru': 'Связи', 'zh': '人脉', 'ja': 'つながり', 'ko': '인맥', 'hi': 'कनेक्शन', 'ar': 'الروابط'},
    'liveStreams': {'en': 'Live Streams', 'es': 'Transmisiones en vivo', 'fr': 'Diffusions en direct', 'de': 'Live-Streams', 'it': 'Dirette streaming', 'pt': 'Transmissões ao vivo', 'ru': 'Прямые эфиры', 'zh': '直播流', 'ja': 'ライブ配信', 'ko': '라이브 스트림', 'hi': 'लाइव स्ट्रीम', 'ar': 'بث مباشر'},
    'bookmark': {'en': 'Bookmark', 'es': 'Marcador', 'fr': 'Signet', 'de': 'Lesezeichen', 'it': 'Segnalibro', 'pt': 'Favorito', 'ru': 'Закладка', 'zh': '书签', 'ja': 'ブックマーク', 'ko': '북마크', 'hi': 'बुकमार्क', 'ar': 'إشارة مرجعية'},
    'cart': {'en': 'Cart', 'es': 'Carrito', 'fr': 'Panier', 'de': 'Warenkorb', 'it': 'Carrello', 'pt': 'Carrinho', 'ru': 'Корзина', 'zh': '购物车', 'ja': 'カート', 'ko': '장바구니', 'hi': 'कार्ट', 'ar': 'عربة التسوق'},
    'gallery': {'en': 'Gallery', 'es': 'Galería', 'fr': 'Galerie', 'de': 'Galerie', 'it': 'Galleria', 'pt': 'Galeria', 'ru': 'Галерея', 'zh': '画廊', 'ja': 'ギャラリー', 'ko': '갤러리', 'hi': 'गैलरी', 'ar': 'معرض الصور'},
    'camera': {'en': 'Camera', 'es': 'Cámara', 'fr': 'Caméra', 'de': 'Kamera', 'it': 'Fotocamera', 'pt': 'Câmera', 'ru': 'Камера', 'zh': '相机', 'ja': 'カメラ', 'ko': '카메라', 'hi': 'कैमरा', 'ar': 'كاميرا'},
    'helpSupport': {'en': 'Help & Support', 'es': 'Ayuda y soporte', 'fr': 'Aide et support', 'de': 'Hilfe & Support', 'it': 'Aiuto e supporto', 'pt': 'Ajuda e suporte', 'ru': 'Помощь и поддержка', 'zh': '帮助与支持', 'ja': 'ヘルプ＆サポート', 'ko': '도움말 및 지원', 'hi': 'सहायता और समर्थन', 'ar': 'المساعدة والدعم'},
    'streaming': {'en': 'STREAMING', 'es': 'TRANSMISIÓN', 'fr': 'DIFFUSION', 'de': 'STREAMING', 'it': 'STREAMING', 'pt': 'TRANSMISSÃO', 'ru': 'СТРИМИНГ', 'zh': '流媒体', 'ja': 'ストリーミング', 'ko': '스트리밍', 'hi': 'स्ट्रीमिंग', 'ar': 'بث'},
    'post': {'en': 'Post', 'es': 'Publicación', 'fr': 'Publication', 'de': 'Beitrag', 'it': 'Post', 'pt': 'Publicação', 'ru': 'Пост', 'zh': '帖子', 'ja': '投稿', 'ko': '게시물', 'hi': 'पोस्ट', 'ar': 'منشور'},
    'submit': {'en': 'Submit', 'es': 'Enviar', 'fr': 'Soumettre', 'de': 'Absenden', 'it': 'Invia', 'pt': 'Enviar', 'ru': 'Отправить', 'zh': '提交', 'ja': '送信', 'ko': '제출', 'hi': 'जमा करें', 'ar': 'إرسال'},
    'confirm': {'en': 'Confirm', 'es': 'Confirmar', 'fr': 'Confirmer', 'de': 'Bestätigen', 'it': 'Conferma', 'pt': 'Confirmar', 'ru': 'Подтвердить', 'zh': '确认', 'ja': '確認', 'ko': '확인', 'hi': 'पुष्टि करें', 'ar': 'تأكيد'},
    'followerLabel': {'en': 'followers', 'es': 'seguidores', 'fr': 'abonnés', 'de': 'follower', 'it': 'seguaci', 'pt': 'seguidores', 'ru': 'подписчиков', 'zh': '粉丝', 'ja': 'フォロワー', 'ko': '팔로워', 'hi': 'फॉलोअर्स', 'ar': 'متابعين'},
    'followingLabel': {'en': 'following', 'es': 'siguiendo', 'fr': 'abonnements', 'de': 'gefolgt', 'it': 'seguiti', 'pt': 'seguindo', 'ru': 'подписок', 'zh': '关注', 'ja': 'フォロー中', 'ko': '팔로잉', 'hi': 'फॉलोइंग', 'ar': 'أتابع'},
    'suggestedForYou': {'en': 'Suggested For You', 'es': 'Sugerido para ti', 'fr': 'Suggéré pour vous', 'de': 'Für dich vorgeschlagen', 'it': 'Suggerito per te', 'pt': 'Sugerido para você', 'ru': 'Рекомендовано для вас', 'zh': '为您推荐', 'ja': 'おすすめ', 'ko': '회원님을 위한 추천', 'hi': 'आपके लिए सुझाव', 'ar': 'مقترح لك'},
    'noResultsFoundFor': {'en': 'No results found for', 'es': 'No se encontraron resultados para', 'fr': 'Aucun résultat trouvé pour', 'de': 'Keine Ergebnisse gefunden für', 'it': 'Nessun risultato trovato per', 'pt': 'Nenhum resultado encontrado para', 'ru': 'Ничего не найдено для', 'zh': '未找到结果', 'ja': '結果が見つかりません', 'ko': '검색 결과 없음', 'hi': 'इसके लिए कोई परिणाम नहीं मिला', 'ar': 'لم يتم العثور على نتائج لـ'},
    'noPostsYet': {'en': 'No posts yet', 'es': 'Aún no hay publicaciones', 'fr': 'Pas encore de publications', 'de': 'Noch keine Beiträge', 'it': 'Nessun post ancora', 'pt': 'Nenhuma publicação ainda', 'ru': 'Пока нет постов', 'zh': '暂无帖子', 'ja': 'まだ投稿はありません', 'ko': '아직 게시물이 없습니다', 'hi': 'अभी कोई पोस्ट नहीं', 'ar': 'لا توجد منشورات بعد'},
}

with open('lib/l10n/app_en.arb', 'r', encoding='utf-8') as f:
    en_template = json.load(f)

output_dir = 'lib/l10n'
for lang_code in languages.keys():
    if lang_code == 'en': continue
    file_name = f"app_zh_Hant.arb" if lang_code == 'zh_Hant' else f"app_{lang_code}.arb"
    file_path = os.path.join(output_dir, file_name)
    
    # Start with English template to ensure all keys are present
    new_data = en_template.copy()
    new_data["@@locale"] = lang_code
    
    # Check if file exists and load existing translations
    if os.path.exists(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                existing_data = json.load(f)
                
            # Preserve existing translations if they are different from English keys
            # or if the English key is very short (likely not a real sentence but a label that could be same)
            # Actually, easiest is to trust existing translation if it exists for the key.
            for key, value in existing_data.items():
                if key in new_data and key != "@@locale":
                    # Only keep if the value is not just the key name (unless en value is also key name)
                    # and if valid string
                    if isinstance(value, str) and value.strip():
                        new_data[key] = value
        except Exception as e:
            print(f"Error reading existing file {file_name}: {e}")

    # RESTORE CORE TRANSLATIONS
    for key, values in core_translations.items():
        if lang_code in values:
             new_data[key] = values[lang_code]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, ensure_ascii=False, indent=2)

print("Updated arb files (merged with existing).")

