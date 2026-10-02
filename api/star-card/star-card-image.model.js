// ตัวอย่าง — วางที่ microservices/user-service/src/models/star-card-image.model.js
// รูปที่การ์ดใช้ — ตัวรูปจริงอยู่ใน image-service เหมือน user_creator_images
// ตารางนี้มีไว้ 2 อย่าง: เช็กว่า imageId ใน doc เป็นของเจ้าของการ์ดจริง และเก็บกวาดรูปที่ไม่ถูกใช้แล้ว
import moment from 'moment'

export default (sequelize, { DATE, INTEGER, STRING }, dbConfig, Sequelize) => {
  const fnDateNow = () => moment().utcOffset('+07:00').format('YYYY-MM-DDTHH:mm:ss+07:00')

  const attributes = {
    cardId: {
      primaryKey: true,
      field: 'card_id',
      type: INTEGER,
      allowNull: false
    },
    imageId: {
      primaryKey: true,
      field: 'image_id',
      type: INTEGER,
      allowNull: false
    },
    // slot = รูปในช่อง widget · lift = รูปที่ลบพื้นหลังแล้ว (PNG โปร่งใส)
    // background = รูปพื้นหลังการ์ด · page = PNG ทั้งหน้าตอนเผยแพร่
    role: {
      type: STRING(16),
      allowNull: false,
      validate: { isIn: { args: [['slot', 'lift', 'background', 'page']], msg: 'ประเภทรูปไม่ถูกต้อง' } }
    },
    createdAt: { type: DATE, defaultValue: fnDateNow },
    updatedAt: { type: DATE, defaultValue: fnDateNow }
  }

  const options = {
    modelName: 'StarCardImage',
    tableName: 'star_card_images',
    timestamps: true,
    underscored: true,
    schema: dbConfig.schema,
    sequelize
  }

  class StarCardImage extends Sequelize.Model {}
  StarCardImage.init(attributes, options)
  StarCardImage.associate = (models) => {
    StarCardImage.belongsTo(models.StarCard, {
      foreignKey: { name: 'cardId', field: 'card_id' }
    })
  }

  return StarCardImage
}
