"""Script para popular o banco de dados com dados iniciais"""
from app.extensions import db
from app.models import Tema


def seed_database():
    """Popula o banco com dados iniciais"""

    # Verifica se já tem dados
    if Tema.query.first() is not None:
        print("✅ Banco já está populado, pulando seed...")
        return

    print("🌱 Populando banco de dados com dados iniciais...")

    # Temas
    temas_data = [
        {'id_tema': 1, 'tema': 'Tecnologia'},
        {'id_tema': 2, 'tema': 'Segurança'},
        {'id_tema': 3, 'tema': 'Economia'},
        {'id_tema': 4, 'tema': 'Meio Ambiente'},
        {'id_tema': 5, 'tema': 'Educação'},
        {'id_tema': 6, 'tema': 'Saúde'},
    ]

    for tema_data in temas_data:
        tema = Tema(**tema_data)
        db.session.add(tema)

    try:
        db.session.commit()
        print("✅ Dados iniciais inseridos com sucesso!")
    except Exception as e:
        db.session.rollback()
        print(f"❌ Erro ao inserir dados: {e}")


if __name__ == '__main__':
    from app import create_app
    app = create_app()
    with app.app_context():
        seed_database()
