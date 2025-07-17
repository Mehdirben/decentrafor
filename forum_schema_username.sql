-- Username-based Forum Database Schema for Supabase
-- This file contains the database structure for the educational forum feature without authentication

-- Enable Row Level Security
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT ALL ON TABLES TO anon, authenticated, service_role;

-- Create forum_users table (replaces auth dependency)
CREATE TABLE IF NOT EXISTS forum_users (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    username VARCHAR(20) UNIQUE NOT NULL,
    display_name VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create forum_categories table
CREATE TABLE IF NOT EXISTS forum_categories (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT NOT NULL,
    icon VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create forum_topics table
CREATE TABLE IF NOT EXISTS forum_topics (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category_id UUID NOT NULL REFERENCES forum_categories(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES forum_users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    views_count INTEGER DEFAULT 0,
    is_pinned BOOLEAN DEFAULT FALSE,
    is_locked BOOLEAN DEFAULT FALSE
);

-- Create forum_posts table
CREATE TABLE IF NOT EXISTS forum_posts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    content TEXT NOT NULL,
    topic_id UUID NOT NULL REFERENCES forum_topics(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES forum_users(id) ON DELETE CASCADE,
    parent_post_id UUID REFERENCES forum_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_edited BOOLEAN DEFAULT FALSE,
    attachments JSONB DEFAULT '[]'
);

-- Create forum_post_likes table
CREATE TABLE IF NOT EXISTS forum_post_likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES forum_users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(post_id, user_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_forum_users_username ON forum_users(username);
CREATE INDEX IF NOT EXISTS idx_forum_users_created_at ON forum_users(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_forum_topics_category_id ON forum_topics(category_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_author_id ON forum_topics(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_topics_created_at ON forum_topics(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_forum_topics_pinned ON forum_topics(is_pinned DESC, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_forum_posts_topic_id ON forum_posts(topic_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_author_id ON forum_posts(author_id);
CREATE INDEX IF NOT EXISTS idx_forum_posts_created_at ON forum_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_forum_posts_parent_id ON forum_posts(parent_post_id);

CREATE INDEX IF NOT EXISTS idx_forum_post_likes_post_id ON forum_post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_forum_post_likes_user_id ON forum_post_likes(user_id);

-- Create updated_at triggers
CREATE OR REPLACE FUNCTION handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER forum_users_updated_at
    BEFORE UPDATE ON forum_users
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER forum_categories_updated_at
    BEFORE UPDATE ON forum_categories
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER forum_topics_updated_at
    BEFORE UPDATE ON forum_topics
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

CREATE TRIGGER forum_posts_updated_at
    BEFORE UPDATE ON forum_posts
    FOR EACH ROW EXECUTE FUNCTION handle_updated_at();

-- Row Level Security Policies (Open access since no authentication required)

-- Forum Users (public read, public write for registration)
ALTER TABLE forum_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum users" ON forum_users
    FOR SELECT USING (true);

CREATE POLICY "Anyone can register as a user" ON forum_users
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update their own info" ON forum_users
    FOR UPDATE USING (true);

-- Forum Categories (public read and write)
ALTER TABLE forum_categories ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum categories" ON forum_categories
    FOR SELECT USING (true);

CREATE POLICY "Anyone can create categories" ON forum_categories
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update categories" ON forum_categories
    FOR UPDATE USING (true);

-- Forum Topics (public read and write)
ALTER TABLE forum_topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum topics" ON forum_topics
    FOR SELECT USING (true);

CREATE POLICY "Anyone can create topics" ON forum_topics
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update topics" ON forum_topics
    FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete topics" ON forum_topics
    FOR DELETE USING (true);

-- Forum Posts (public read and write)
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view forum posts" ON forum_posts
    FOR SELECT USING (true);

CREATE POLICY "Anyone can create posts" ON forum_posts
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Anyone can update posts" ON forum_posts
    FOR UPDATE USING (true);

CREATE POLICY "Anyone can delete posts" ON forum_posts
    FOR DELETE USING (true);

-- Forum Post Likes (public access)
ALTER TABLE forum_post_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view likes" ON forum_post_likes
    FOR SELECT USING (true);

CREATE POLICY "Anyone can manage likes" ON forum_post_likes
    FOR ALL USING (true);

-- Insert some sample forum categories
INSERT INTO forum_categories (name, description, icon) VALUES
('Mathematics', 'Discuss mathematical concepts, problems, and solutions', 'math'),
('Science', 'Share scientific discoveries, experiments, and theories', 'science'),
('Literature', 'Explore books, poetry, writing techniques, and literary analysis', 'literature'),
('History', 'Learn and discuss historical events, figures, and cultures', 'history'),
('Technology', 'Computer science, programming, and technology discussions', 'technology'),
('Art & Design', 'Creative arts, design principles, and artistic techniques', 'art'),
('Language Learning', 'Practice languages, grammar, and cultural exchange', 'language'),
('General Discussion', 'Open discussions about education and learning', 'general')
ON CONFLICT DO NOTHING;

-- Create a view for topic statistics
CREATE OR REPLACE VIEW forum_topic_stats AS
SELECT 
    t.id,
    t.title,
    t.description,
    t.category_id,
    t.author_id,
    t.created_at,
    t.updated_at,
    t.views_count,
    t.is_pinned,
    t.is_locked,
    u.display_name as author_name,
    COUNT(fp.id) as posts_count,
    MAX(fp.created_at) as last_post_at
FROM forum_topics t
LEFT JOIN forum_users u ON t.author_id = u.id
LEFT JOIN forum_posts fp ON t.id = fp.topic_id
GROUP BY t.id, t.title, t.description, t.category_id, t.author_id, t.created_at, t.updated_at, t.views_count, t.is_pinned, t.is_locked, u.display_name;

-- Create a view for category statistics
CREATE OR REPLACE VIEW forum_category_stats AS
SELECT 
    c.id,
    c.name,
    c.description,
    c.icon,
    c.created_at,
    c.updated_at,
    COUNT(DISTINCT t.id) as topics_count,
    COUNT(fp.id) as posts_count
FROM forum_categories c
LEFT JOIN forum_topics t ON c.id = t.category_id
LEFT JOIN forum_posts fp ON t.id = fp.topic_id
GROUP BY c.id, c.name, c.description, c.icon, c.created_at, c.updated_at;

-- Create some sample users for testing
INSERT INTO forum_users (username, display_name) VALUES
('admin', 'Administrator'),
('teacher_smith', 'Professor Smith'),
('student_alice', 'Alice Cooper'),
('mathwiz', 'Math Wizard'),
('sciencefan', 'Science Enthusiast')
ON CONFLICT DO NOTHING;

-- Create some sample topics for testing
INSERT INTO forum_topics (title, description, category_id, author_id) 
SELECT 
    'Welcome to Mathematics Discussion',
    'This is a place to discuss all things mathematical! Feel free to ask questions, share interesting problems, or discuss mathematical concepts.',
    c.id,
    u.id
FROM forum_categories c, forum_users u 
WHERE c.name = 'Mathematics' AND u.username = 'admin'
ON CONFLICT DO NOTHING;

INSERT INTO forum_topics (title, description, category_id, author_id) 
SELECT 
    'Introduction to Scientific Method',
    'Let''s discuss the fundamentals of scientific inquiry and research methodologies.',
    c.id,
    u.id
FROM forum_categories c, forum_users u 
WHERE c.name = 'Science' AND u.username = 'teacher_smith'
ON CONFLICT DO NOTHING;

-- Create some sample posts
INSERT INTO forum_posts (content, topic_id, author_id)
SELECT 
    'Welcome everyone! I''m excited to see what mathematical discussions we''ll have here. Don''t hesitate to ask questions, no matter how basic they might seem.',
    t.id,
    u.id
FROM forum_topics t, forum_users u
WHERE t.title = 'Welcome to Mathematics Discussion' AND u.username = 'admin'
ON CONFLICT DO NOTHING;
