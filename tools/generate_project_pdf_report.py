from __future__ import annotations

from datetime import datetime
from pathlib import Path
import os

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import cm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    HRFlowable,
    Image,
    PageBreak,
    Paragraph,
    SimpleDocTemplate,
    Spacer,
    Table,
    TableStyle,
)


ROOT = Path(__file__).resolve().parents[1]
OUTPUT_DIR = ROOT / "docs"
OUTPUT_PDF = OUTPUT_DIR / "BonPlanFinder_Rapport_Complet.pdf"
LOGO_PATH = ROOT / "assets" / "images" / "BonPlanFinder.png"


def register_fonts() -> tuple[str, str]:
    candidates = [
        ("ArialUnicode", "ArialUnicode-Bold", r"C:\Windows\Fonts\arial.ttf", r"C:\Windows\Fonts\arialbd.ttf"),
        ("DejaVuSans", "DejaVuSans-Bold", r"C:\Windows\Fonts\DejaVuSans.ttf", r"C:\Windows\Fonts\DejaVuSans-Bold.ttf"),
    ]
    for regular_name, bold_name, regular_path, bold_path in candidates:
        if os.path.exists(regular_path) and os.path.exists(bold_path):
            pdfmetrics.registerFont(TTFont(regular_name, regular_path))
            pdfmetrics.registerFont(TTFont(bold_name, bold_path))
            return regular_name, bold_name
    return "Helvetica", "Helvetica-Bold"


REGULAR_FONT, BOLD_FONT = register_fonts()


def build_styles():
    styles = getSampleStyleSheet()
    styles.add(
        ParagraphStyle(
            name="ReportTitle",
            parent=styles["Title"],
            fontName=BOLD_FONT,
            fontSize=24,
            leading=30,
            textColor=colors.HexColor("#14532D"),
            alignment=TA_CENTER,
            spaceAfter=12,
        )
    )
    styles.add(
        ParagraphStyle(
            name="ReportSubTitle",
            parent=styles["Heading2"],
            fontName=REGULAR_FONT,
            fontSize=12,
            leading=18,
            textColor=colors.HexColor("#334155"),
            alignment=TA_CENTER,
            spaceAfter=8,
        )
    )
    styles.add(
        ParagraphStyle(
            name="SectionHeading",
            parent=styles["Heading1"],
            fontName=BOLD_FONT,
            fontSize=18,
            leading=22,
            textColor=colors.HexColor("#0F172A"),
            spaceBefore=10,
            spaceAfter=10,
        )
    )
    styles.add(
        ParagraphStyle(
            name="SubHeading",
            parent=styles["Heading2"],
            fontName=BOLD_FONT,
            fontSize=13,
            leading=17,
            textColor=colors.HexColor("#1E293B"),
            spaceBefore=8,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BodyJustify",
            parent=styles["BodyText"],
            fontName=REGULAR_FONT,
            fontSize=10.5,
            leading=15,
            alignment=TA_JUSTIFY,
            spaceAfter=6,
        )
    )
    styles.add(
        ParagraphStyle(
            name="SmallBody",
            parent=styles["BodyText"],
            fontName=REGULAR_FONT,
            fontSize=9.2,
            leading=13,
            alignment=TA_JUSTIFY,
            spaceAfter=4,
        )
    )
    styles.add(
        ParagraphStyle(
            name="BulletBody",
            parent=styles["BodyText"],
            fontName=REGULAR_FONT,
            fontSize=10.2,
            leading=14,
            leftIndent=14,
            firstLineIndent=-8,
            bulletIndent=0,
            spaceAfter=3,
        )
    )
    return styles


STYLES = build_styles()


FILE_DESCRIPTIONS = {
    "lib/main.dart": (
        "Point d'entrée de l'application. Initialise Flutter, ouvre la base SQLite, instancie les services et injecte les providers dans l'arbre widget via MultiProvider. "
        "Ce fichier configure également le thème global, le titre de l'application et la route dynamique vers l'écran d'ajout/modification d'avis."
    ),
    "lib/config/app_constants.dart": (
        "Centralise toutes les constantes du projet : nom de l'application, version de base de données, noms des tables SQLite, paramètres API Overpass, limites de validation et messages d'erreur."
    ),
    "lib/config/app_theme.dart": (
        "Définit le thème visuel global de BonPlanFinder : couleurs, styles de texte, composants Material et cohérence graphique entre les écrans."
    ),
    "lib/models/user_model.dart": (
        "Modèle de données représentant un utilisateur local. Contient les champs de profil, les méthodes de sérialisation map/fromMap et sert d'interface entre SQLite et les providers."
    ),
    "lib/models/restaurant_model.dart": (
        "Modèle central de l'application. Représente un restaurant ou café avec coordonnées, adresse, téléphone, description, images, note moyenne, origine du lieu et métadonnées de communauté."
    ),
    "lib/models/review_model.dart": (
        "Modèle d'avis utilisateur. Transporte l'identifiant du lieu, l'auteur, la note, le commentaire et les dates de création/mise à jour."
    ),
    "lib/models/favorite_model.dart": (
        "Modèle de favori reliant un utilisateur et un lieu. Utilisé pour la persistance et la logique de favoris."
    ),
    "lib/models/nearby_places_result.dart": (
        "Objet de résultat enrichi pour le chargement des lieux proches. Transporte la liste de restaurants, l'information de fallback cache et un message d'état éventuel."
    ),
    "lib/services/database_service.dart": (
        "Service bas niveau pour l'accès SQLite. Crée les tables, gère les migrations, active les clés étrangères et normalise les données après mise à jour de schéma."
    ),
    "lib/services/auth_service.dart": (
        "Service métier d'authentification locale. Gère inscription, connexion, restauration de session, déconnexion et mise à jour de la photo de profil. Utilise SHA-256 via PasswordUtils."
    ),
    "lib/services/session_service.dart": (
        "Encapsule SharedPreferences pour sauvegarder et relire la session utilisateur locale."
    ),
    "lib/services/location_service.dart": (
        "Service dédié à la géolocalisation. Interroge Geolocator, vérifie les permissions et renvoie la position courante."
    ),
    "lib/services/api_service.dart": (
        "Service réseau principal. Construit les requêtes Overpass, interroge plusieurs endpoints miroir, parse la réponse JSON, déduplique les résultats et enrichit les informations des lieux."
    ),
    "lib/services/overpass_service.dart": (
        "Ancien ou service alternatif pour Overpass. Il sert de point de comparaison ou de version simplifiée de l'accès API."
    ),
    "lib/services/restaurant_service.dart": (
        "Service métier le plus riche du projet. Coordonne cache local et API distante, gère l'ajout/modification/suppression des lieux communautaires et consolide les données affichées."
    ),
    "lib/services/review_service.dart": (
        "Service CRUD complet pour les avis. Après chaque insertion, modification ou suppression, recalcule la note moyenne et le nombre d'avis du lieu associé."
    ),
    "lib/services/favorites_service.dart": (
        "Service chargé de la gestion des favoris : ajout, suppression, vérification d'existence et chargement des lieux favoris de l'utilisateur."
    ),
    "lib/providers/auth_provider.dart": (
        "Provider d'authentification. Expose l'utilisateur courant, l'état de chargement, les erreurs et des méthodes simples utilisées par l'interface pour login, register, logout et update photo."
    ),
    "lib/providers/location_provider.dart": (
        "Provider de localisation. Sert de couche de présentation entre LocationService et l'interface, avec gestion de chargement et messages d'erreur."
    ),
    "lib/providers/restaurant_provider.dart": (
        "Provider principal de navigation métier. Il charge les lieux proches, trie par distance, applique la recherche, sépare les lieux communautaires et gère les actions d'ajout/modification/suppression."
    ),
    "lib/providers/review_provider.dart": (
        "Provider des avis. Ordonne le chargement par lieu, l'ajout, l'édition, la suppression et expose l'avis personnel de l'utilisateur connecté."
    ),
    "lib/providers/favorites_provider.dart": (
        "Provider des favoris. Met à disposition la liste des lieux favoris, l'état de chargement et le toggle instantané de l'état favori."
    ),
    "lib/screens/splash_screen.dart": (
        "Écran de démarrage. Initialise l'application, restaure la session et redirige vers l'écran de connexion ou d'accueil."
    ),
    "lib/screens/login_screen.dart": (
        "Écran de connexion avec branding de l'application. Permet à l'utilisateur d'entrer email et mot de passe, puis lance l'authentification via AuthProvider."
    ),
    "lib/screens/register_screen.dart": (
        "Écran de création de compte. Collecte les informations de base d'un nouvel utilisateur et délègue la création au provider d'authentification."
    ),
    "lib/screens/home_screen.dart": (
        "Écran central de l'application. Affiche les lieux proches, la recherche, le rafraîchissement, l'ajout communautaire, les messages d'état et les autres onglets."
    ),
    "lib/screens/nearby_places_screen.dart": (
        "Vue dédiée affichant la liste complète des lieux proches quand l'utilisateur demande plus que l'aperçu de l'écran d'accueil."
    ),
    "lib/screens/add_place_screen.dart": (
        "Formulaire d'ajout ou modification d'un lieu communautaire. Gère validation, images multiples, capture photo caméra et envoi vers RestaurantProvider."
    ),
    "lib/screens/restaurant_detail_screen.dart": (
        "Écran de détail d'un lieu. Présente galerie d'images, informations issues de l'API, favoris, édition/suppression pour l'auteur et bloc complet des avis."
    ),
    "lib/screens/add_review_screen.dart": (
        "Écran d'ajout ou modification d'avis. Pré-remplit les champs en mode édition, valide la note/commentaire puis délègue au ReviewProvider."
    ),
    "lib/screens/favorites_screen.dart": (
        "Écran listant les restaurants et cafés favoris de l'utilisateur connecté."
    ),
    "lib/screens/profile_screen.dart": (
        "Écran de profil utilisateur. Affiche les statistiques, l'image de profil et permet de changer la photo via la galerie."
    ),
    "lib/utils/password_utils.dart": (
        "Fonctions utilitaires liées à la sécurité, notamment le hachage SHA-256 des mots de passe."
    ),
    "lib/utils/validators.dart": (
        "Bibliothèque de validation des formulaires. Centralise les règles pour email, mot de passe, commentaires, adresses, téléphone et autres champs."
    ),
    "lib/utils/date_utils.dart": (
        "Fonctions de formatage de dates affichées dans l'interface, notamment pour les avis et métadonnées temporelles."
    ),
    "lib/widgets/app_text_field.dart": (
        "Champ de saisie réutilisable stylisé, utilisé dans la plupart des formulaires de l'application."
    ),
    "lib/widgets/primary_button.dart": (
        "Bouton principal réutilisable avec état de chargement intégré."
    ),
    "lib/widgets/empty_state.dart": (
        "Widget réutilisable d'état vide pour afficher une icône, un titre et un message explicatif."
    ),
    "lib/widgets/error_view.dart": (
        "Widget réutilisable d'affichage d'erreur avec action de relance."
    ),
    "lib/widgets/loading_view.dart": (
        "Widget d'attente générique pour les écrans ou sections en chargement."
    ),
    "lib/widgets/rating_stars.dart": (
        "Composant visuel qui affiche la note sur cinq étoiles."
    ),
    "lib/widgets/restaurant_card.dart": (
        "Carte réutilisable pour afficher un lieu dans les listes, avec nom, type, image, note, badge communautaire et action favori."
    ),
    "lib/widgets/review_card.dart": (
        "Carte réutilisable pour afficher un avis utilisateur avec actions éventuelles d'édition ou suppression."
    ),
}


CORE_FILE_ANALYSIS = [
    (
        "main.dart",
        [
            "Le bloc main() appelle WidgetsFlutterBinding.ensureInitialized() pour autoriser les opérations asynchrones avant runApp, notamment l'ouverture de SQLite.",
            "Les services sont instanciés une seule fois puis injectés dans les providers. Cela évite les créations multiples et simplifie les tests.",
            "Le widget RestaurantFinderApp encapsule toute l'application dans un MultiProvider, ce qui garantit un accès global à l'état d'authentification, de localisation, de restaurants, d'avis et de favoris.",
            "onGenerateRoute gère explicitement la navigation vers AddReviewScreen en acceptant soit un ReviewModel direct, soit une Map d'arguments. Ce choix a permis de corriger des problèmes de navigation rencontrés auparavant.",
        ],
    ),
    (
        "database_service.dart",
        [
            "Le service suit un pattern singleton via DatabaseService.instance. Cela garantit qu'une seule connexion SQLite est ouverte dans l'application.",
            "La méthode _onCreate définit quatre tables : users, restaurants, reviews et favorites. Les relations de clés étrangères servent à maintenir l'intégrité des données.",
            "La méthode _onUpgrade gère l'évolution progressive du schéma. C'est essentiel pour ne pas casser les installations existantes lorsque de nouveaux champs sont ajoutés.",
            "Les méthodes _normalizeRestaurantData et _normalizeUserData corrigent les valeurs nulles héritées d'anciennes versions. C'est une sécurité importante pour éviter des plantages côté Dart avec null safety.",
        ],
    ),
    (
        "auth_service.dart",
        [
            "register() normalise l'email, valide les données, vérifie l'unicité dans SQLite, hache le mot de passe puis crée l'utilisateur avant de sauvegarder la session.",
            "login() recharge l'utilisateur à partir de la base, recalcule le hash du mot de passe saisi et compare les deux valeurs. Aucun mot de passe en clair n'est conservé.",
            "tryAutoLogin() relit la session SharedPreferences et vérifie que l'utilisateur existe toujours dans la base. Si ce n'est plus le cas, la session est supprimée proprement.",
            "L'ensemble des validations est factorisé dans des méthodes privées pour garder un service lisible et limiter la duplication.",
        ],
    ),
    (
        "api_service.dart",
        [
            "Le service construit une requête Overpass pour récupérer restaurants et cafés autour des coordonnées GPS courantes.",
            "Plusieurs endpoints miroir sont testés successivement pour améliorer la robustesse lorsque le serveur principal est indisponible.",
            "La méthode _mapRestaurant transforme la structure JSON Overpass en RestaurantModel et enrichit l'adresse, le téléphone, la cuisine et les détails exploitables dans l'écran de détail.",
            "Le code applique un filtrage de sécurité pour ignorer les entrées sans coordonnées exploitables et déduplique les résultats via remoteId.",
        ],
    ),
    (
        "restaurant_service.dart",
        [
            "getNearbyRestaurants() choisit entre cache local et données live selon le paramètre forceRefresh et la validité temporelle du cache.",
            "En cas d'échec réseau ou timeout, le service peut renvoyer les données sauvegardées avec un message de fallback ; cela améliore l'expérience utilisateur en mode dégradé.",
            "Les méthodes addUserPlace(), updateUserPlace() et deleteUserPlace() sécurisent les actions communautaires et vérifient que seul le créateur peut modifier son contenu.",
            "La méthode _saveNearbyRestaurants() fusionne la réponse API avec les valeurs locales utiles comme les notes, le nombre d'avis ou les images associées.",
        ],
    ),
    (
        "restaurant_provider.dart",
        [
            "Ce provider est le point d'entrée principal de la logique écran pour les restaurants : chargement, tri, recherche, preview des dix premiers résultats et section séparée Community Picks.",
            "Le getter restaurants filtre d'abord les lieux non communautaires, applique la recherche puis trie par distance avec Geolocator.distanceBetween.",
            "nearbyPreviewRestaurants permet d'afficher seulement dix cartes sur l'accueil tout en conservant une recherche complète sur l'ensemble des résultats chargés.",
            "La séparation entre services et provider est nette : le provider orchestre l'état et les notifyListeners(), tandis que la logique d'accès aux données reste dans RestaurantService.",
        ],
    ),
    (
        "add_place_screen.dart",
        [
            "Le formulaire utilise des contrôleurs dédiés et les validateurs centralisés. Le flux de soumission reste simple et lisible.",
            "La section image a été étendue pour accepter plusieurs photos via la galerie et une capture directe via la caméra.",
            "Pour rester compatible avec le stockage existant, plusieurs chemins d'images sont sérialisés dans le champ imagePath avec un séparateur dédié défini dans RestaurantModel.",
            "L'écran a été simplifié côté localisation : l'utilisateur saisit uniquement l'adresse, tandis que les coordonnées de secours restent gérées côté logique métier.",
        ],
    ),
    (
        "restaurant_detail_screen.dart",
        [
            "L'écran recharge dynamiquement les avis, l'état favori et les dernières données du restaurant afin d'éviter les informations obsolètes.",
            "Les détails issus de l'API sont extraits depuis la description structurée puis affichés dans une section Place details plus lisible.",
            "La galerie supérieure affiche désormais toutes les images enregistrées pour un lieu grâce au getter imagePaths du modèle.",
            "Les droits d'édition et suppression sont évalués à partir de createdBy, ce qui protège les données communautaires des autres utilisateurs.",
        ],
    ),
]


ARCHITECTURE_POINTS = [
    "Architecture logique : UI (screens/widgets) -> Providers -> Services -> SQLite / API Overpass.",
    "Gestion d'état centralisée avec Provider pour séparer clairement la logique de présentation du stockage et des appels réseau.",
    "Persistance locale complète avec SQLite pour utilisateurs, lieux, avis et favoris.",
    "Session locale via SharedPreferences pour auto-login sans serveur distant.",
    "Support des erreurs réseau, du cache et des messages explicites en interface.",
]


FEATURES = [
    "Authentification locale avec inscription, connexion, auto-login et déconnexion.",
    "Gestion de photo de profil utilisateur depuis la galerie.",
    "Détection GPS de la position courante.",
    "Chargement des restaurants et cafés proches via Overpass API.",
    "Mise en cache locale des lieux récupérés.",
    "Recherche textuelle multicritère sur les lieux chargés.",
    "Affichage preview des dix lieux proches et écran séparé pour la liste complète.",
    "Ajout, modification et suppression de lieux communautaires.",
    "Support de plusieurs images pour un lieu, avec galerie et capture caméra.",
    "Système complet de favoris.",
    "CRUD complet des avis avec recalcul automatique de la note moyenne.",
    "Affichage détaillé des informations renvoyées par l'API : adresse, téléphone, cuisine et métadonnées utiles.",
]


def add_title_page(story: list):
    if LOGO_PATH.exists():
        story.append(Image(str(LOGO_PATH), width=4.2 * cm, height=4.2 * cm))
        story.append(Spacer(1, 0.3 * cm))
    story.append(Paragraph("Rapport détaillé du projet BonPlanFinder", STYLES["ReportTitle"]))
    story.append(
        Paragraph(
            "Application Flutter de découverte de restaurants et cafés avec communauté, favoris, avis et persistance locale",
            STYLES["ReportSubTitle"],
        )
    )
    story.append(Spacer(1, 0.6 * cm))
    story.append(HRFlowable(width="80%", thickness=1, color=colors.HexColor("#CBD5E1")))
    story.append(Spacer(1, 0.6 * cm))
    intro = (
        "Ce document présente une analyse complète du projet : objectifs fonctionnels, architecture technique, "
        "explication détaillée du fonctionnement du code et rôle de chaque fichier du dossier <b>lib/</b>."
    )
    story.append(Paragraph(intro, STYLES["BodyJustify"]))
    story.append(Spacer(1, 0.6 * cm))
    story.append(
        Paragraph(
            f"Généré automatiquement le {datetime.now().strftime('%d/%m/%Y à %H:%M')}",
            STYLES["ReportSubTitle"],
        )
    )
    story.append(PageBreak())


def add_section(story: list, title: str):
    story.append(Paragraph(title, STYLES["SectionHeading"]))


def add_bullets(story: list, items: list[str]):
    for item in items:
        story.append(Paragraph(f"• {item}", STYLES["BulletBody"]))


def add_file_table(story: list, rows: list[tuple[str, str]]):
    table_data = [["Fichier", "Rôle dans le projet"]]
    table_data.extend(rows)
    table = Table(table_data, colWidths=[5.3 * cm, 10.8 * cm], repeatRows=1)
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#14532D")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
                ("FONTNAME", (0, 0), (-1, 0), BOLD_FONT),
                ("FONTNAME", (0, 1), (-1, -1), REGULAR_FONT),
                ("FONTSIZE", (0, 0), (-1, -1), 8.9),
                ("LEADING", (0, 0), (-1, -1), 11),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.whitesmoke, colors.HexColor("#F8FAFC")]),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#CBD5E1")),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.append(table)


def grouped_rows(prefix: str) -> list[tuple[str, str]]:
    rows = []
    for path, description in FILE_DESCRIPTIONS.items():
        if path.startswith(prefix):
            rows.append((path.replace("lib/", ""), description))
    rows.sort(key=lambda item: item[0])
    return rows


def build_report():
    OUTPUT_DIR.mkdir(exist_ok=True)
    doc = SimpleDocTemplate(
        str(OUTPUT_PDF),
        pagesize=A4,
        leftMargin=1.7 * cm,
        rightMargin=1.7 * cm,
        topMargin=1.5 * cm,
        bottomMargin=1.5 * cm,
        title="Rapport complet BonPlanFinder",
        author="OpenAI Codex",
    )

    story: list = []
    add_title_page(story)

    add_section(story, "1. Vue d'ensemble du projet")
    story.append(
        Paragraph(
            "BonPlanFinder est une application mobile Flutter orientée découverte locale. Elle combine quatre idées fortes : "
            "la géolocalisation, la recherche de lieux proches, la contribution communautaire et la gestion personnelle "
            "des favoris et avis. Le projet repose sur une architecture claire et modulaire, suffisamment simple pour être maintenable "
            "dans un cadre académique tout en restant proche de bonnes pratiques professionnelles.",
            STYLES["BodyJustify"],
        )
    )
    story.append(Paragraph("<b>Fonctionnalités principales</b>", STYLES["SubHeading"]))
    add_bullets(story, FEATURES)

    story.append(Spacer(1, 0.2 * cm))
    story.append(Paragraph("<b>Pile technique</b>", STYLES["SubHeading"]))
    tech_rows = [
        ("Flutter / Dart", "Interface mobile, navigation, widgets et logique applicative."),
        ("Provider", "Gestion d'état et communication entre UI et services."),
        ("SQLite / sqflite", "Base locale contenant utilisateurs, lieux, avis et favoris."),
        ("SharedPreferences", "Stockage de session pour l'auto-login."),
        ("Overpass API", "Source externe des restaurants et cafés réels autour de la position GPS."),
        ("Geolocator", "Lecture de la position et gestion des permissions de localisation."),
        ("Image Picker", "Import depuis galerie et capture photo caméra."),
        ("Crypto (SHA-256)", "Hachage local des mots de passe."),
    ]
    add_file_table(story, tech_rows)

    add_section(story, "2. Architecture et circulation des données")
    story.append(
        Paragraph(
            "Le projet suit une organisation par responsabilités. L'interface déclenche des actions utilisateur, "
            "les providers maintiennent l'état observable, les services exécutent la logique métier et les accès données, "
            "puis les modèles assurent le transport cohérent des informations entre couches.",
            STYLES["BodyJustify"],
        )
    )
    add_bullets(story, ARCHITECTURE_POINTS)
    story.append(Paragraph("<b>Flux typique : chargement des lieux proches</b>", STYLES["SubHeading"]))
    add_bullets(
        story,
        [
            "HomeScreen demande au LocationProvider d'obtenir la position courante.",
            "RestaurantProvider.loadNearbyRestaurants() transmet latitude et longitude à RestaurantService.",
            "RestaurantService décide d'utiliser soit le cache SQLite, soit ApiService pour un appel Overpass.",
            "ApiService convertit le JSON en RestaurantModel puis renvoie la liste au service.",
            "Le service enregistre les résultats en base puis renvoie un NearbyPlacesResult au provider.",
            "Le provider trie, filtre, découpe éventuellement en aperçu et notifie l'interface via notifyListeners().",
        ],
    )

    story.append(Paragraph("<b>Flux typique : authentification</b>", STYLES["SubHeading"]))
    add_bullets(
        story,
        [
            "LoginScreen ou RegisterScreen collecte les champs du formulaire.",
            "AuthProvider orchestre l'état de chargement et délègue à AuthService.",
            "AuthService valide, interroge SQLite, hache si nécessaire le mot de passe, puis sauvegarde la session.",
            "L'utilisateur authentifié est remonté au provider, ce qui redessine automatiquement l'interface dépendante.",
        ],
    )

    add_section(story, "3. Explication détaillée du code cœur")
    for filename, points in CORE_FILE_ANALYSIS:
        story.append(Paragraph(filename, STYLES["SubHeading"]))
        add_bullets(story, points)

    add_section(story, "4. Rôle détaillé de chaque fichier")
    story.append(
        Paragraph(
            "Cette section sert d'index technique du code. Chaque fichier important du dossier <b>lib/</b> est présenté avec sa responsabilité principale.",
            STYLES["BodyJustify"],
        )
    )
    for group_name, prefix in [
        ("4.1 Configuration", "lib/config/"),
        ("4.2 Modèles", "lib/models/"),
        ("4.3 Services", "lib/services/"),
        ("4.4 Providers", "lib/providers/"),
        ("4.5 Écrans", "lib/screens/"),
        ("4.6 Utilitaires", "lib/utils/"),
        ("4.7 Widgets réutilisables", "lib/widgets/"),
    ]:
        story.append(Paragraph(group_name, STYLES["SubHeading"]))
        add_file_table(story, grouped_rows(prefix))
        story.append(Spacer(1, 0.25 * cm))

    story.append(PageBreak())
    add_section(story, "5. Analyse fonctionnelle détaillée")
    functional_text = (
        "Le comportement de BonPlanFinder montre un découpage propre des responsabilités. L'application n'insère pas de logique métier complexe directement "
        "dans les widgets. Les écrans restent principalement responsables de la composition visuelle, du déclenchement des actions utilisateur et de la navigation. "
        "Les providers jouent le rôle d'orchestrateurs d'état, tandis que les services encapsulent les règles métier et les interactions avec SQLite, SharedPreferences ou l'API Overpass."
    )
    story.append(Paragraph(functional_text, STYLES["BodyJustify"]))

    story.append(Paragraph("Points de qualité observés dans le code", STYLES["SubHeading"]))
    add_bullets(
        story,
        [
            "Null safety respectée dans les modèles et les providers.",
            "Gestion d'erreur systématique avec messages compréhensibles pour l'utilisateur.",
            "Réutilisation de composants UI pour limiter la duplication.",
            "Séparation explicite entre données locales, cache API et lieux communautaires.",
            "Évolutivité du schéma SQLite grâce au système de migrations.",
            "Compatibilité ascendante conservée lors de l'ajout des images multiples en sérialisant plusieurs chemins dans le champ imagePath.",
        ],
    )

    story.append(Paragraph("Exemples de décisions de conception importantes", STYLES["SubHeading"]))
    add_bullets(
        story,
        [
            "Utilisation d'Overpass au lieu d'une API nécessitant une clé pour simplifier le déploiement et les tests.",
            "Conservation d'un cache local des lieux proches pour améliorer la résilience réseau.",
            "Utilisation du pattern singleton pour la base SQLite afin d'éviter les connexions concurrentes.",
            "Encapsulation du calcul de distance et de la logique de recherche dans RestaurantProvider pour garder l'écran Home lisible.",
            "Centralisation des validations dans Validators pour éviter la duplication de règles entre les formulaires.",
        ],
    )

    add_section(story, "6. Schéma logique des données")
    schema_rows = [
        ("users", "Compte local : nom, email, mot de passe haché, photo de profil, date de création."),
        ("restaurants", "Lieux API et lieux communautaires : coordonnées, adresse, type, téléphone, description, images, note moyenne, auteur."),
        ("reviews", "Avis liés à un lieu et à un utilisateur : note, commentaire, dates."),
        ("favorites", "Table de liaison utilisateur-lieu pour les favoris."),
    ]
    add_file_table(story, schema_rows)
    story.append(
        Paragraph(
            "Le schéma est pensé pour supporter un mode majoritairement local. Les tables reviews et favorites référencent respectivement restaurants et users, "
            "ce qui permet de recalculer les statistiques d'un lieu et de retrouver les contenus propres à chaque utilisateur.",
            STYLES["BodyJustify"],
        )
    )

    add_section(story, "7. Conclusion")
    story.append(
        Paragraph(
            "BonPlanFinder est un projet Flutter cohérent et bien structuré. Son architecture par providers et services rend le code accessible, évolutif et pédagogique. "
            "Le projet couvre des thèmes importants du développement mobile : authentification locale, persistance SQLite, consommation d'API, gestion d'état, formulaires, "
            "médias, recherche, favoris et logique communautaire.",
            STYLES["BodyJustify"],
        )
    )
    story.append(
        Paragraph(
            "Ce rapport a été conçu pour servir à la fois de documentation de soutenance, de support de maintenance et de guide de compréhension du code. "
            "Il peut être complété plus tard par des diagrammes UML, un schéma base de données illustré ou une documentation technique par capture d'écran.",
            STYLES["BodyJustify"],
        )
    )

    doc.build(story)


if __name__ == "__main__":
    build_report()
    print(f"PDF generated: {OUTPUT_PDF}")
