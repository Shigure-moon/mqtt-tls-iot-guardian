import os

def update_imports(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py'):
                filepath = os.path.join(root, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                
                # 替换导入路径
                content = content.replace('from app.api.api_v1', 'from app.api.api_v1')
                content = content.replace('import app.api.api_v1', 'import app.api.api_v1')
                
                with open(filepath, 'w') as f:
                    f.write(content)

if __name__ == '__main__':
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    update_imports(backend_dir)