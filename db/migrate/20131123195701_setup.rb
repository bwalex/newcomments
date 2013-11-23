class Setup < ActiveRecord::Migration
  def self.up
    create_table :sites do |t|
      t.string      :name
      t.string      :url
      t.timestamps
    end

    add_index :sites, :name, :unique => true


    create_table :articles do |t|
      t.references  :site
      t.string      :name
      t.string      :hash
      t.timestamps
    end

    add_index :articles, :hash, :unique => true
    add_foreign_key(:articles, :sites, :dependent => :delete)


    create_table :comments do |t|
      t.references  :article
      t.string      :ip
      t.string      :name
      t.string      :email
      t.string      :hashed_email
      t.text        :comment
      t.timestamps
    end

    add_foreign_key(:comments, :articles, :dependent => :delete)


    create_table :users do |t|
      t.string      :email
      t.string      :password
      t.string      :salt
      t.boolean     :admin
      t.timestamps
    end

    add_index :users, :email, :unique => true


    create_table :site_users do |t|
      t.references  :user
      t.references  :site
      t.integer     :access_level
      t.timestamps
    end

    add_foreign_key(:site_users, :users, :dependent => :delete)
    add_foreign_key(:site_users, :sites, :dependent => :delete)
    add_index :site_users, [:site_id, :user_id], :unique => true
  end

  def self.down
    drop_table :comments
    drop_table :articles
    drop_table :sites
    drop_table :users
    drop_table :site_users
  end
end
